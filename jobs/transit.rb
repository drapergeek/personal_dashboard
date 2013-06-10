require 'net/http'
require 'net/https'
require 'uri'
require 'json'


config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/transit.yml'
widgets = YAML::load(File.open(config_file))

class MapRoute
  attr_reader :origin, :destination, :name, :mode, :time

  def initialize(origin_address, destination_information)
    @origin = URI::encode(origin_address)
    @destination = URI::encode(destination_information['address'])
    @name = destination_information['name']
    @mode = URI::encode(destination_information['mode'])
  end

  def lookup_route
    begin
      @time = json_response["routes"][0]["legs"][0]["duration"]["text"]
    rescue
      puts "Failed looking up route"
      print_debug_information

      false
    end
  end

  def print_debug_information
    puts "Origin: #{origin}"
    puts "Destination:#{name} - #{destination}"
    puts "URL: #{api_url}"
    puts "Mode: #{mode}"
    p json_response
  end

  private
  attr_reader :json_response

  def json_response
    @json_response ||= lookup_server_response
  end

  def lookup_server_response
    uri = URI.parse(api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    JSON.parse(response.body)
  end

  def api_url
    "https://maps.googleapis.com/maps/api/directions/json?origin=#{origin}&destination=#{destination}&sensor=false&mode=#{mode}&departure_time=1370828582"
  end
end

SCHEDULER.every '10m', :first_in => '5s' do |job|
  widgets.each do |name, information_hash|
    origin = information_hash['origin']
    widget_name ="transit-#{name}"
    routes = []

    information_hash['locations'].each do |location|
      location = MapRoute.new(origin, location)
      if location.lookup_route
        routes << {name: location.name, time: location.time }
      end
    end

    sleep 5 #sleep to prevent hitting the google API limits
    send_event(widget_name, { results: routes } )
  end
end

