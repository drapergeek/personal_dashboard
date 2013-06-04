class WeatherUpdater
  attr_accessor :name, :woe_id,  :format

  def initialize(name, woe_id, format='f')
    @name = name
    @woe_id = woe_id
    @format = format
  end

  def update
    send_event( widget_name,
               { :temp => temp,
                 :condition => conditions,
                 :title => title
               }
              )
  end

  private

  def widget_name
    "weather-#{name.downcase}"
  end

  def temp
    "#{weather_data['temp']}&deg;#{format.upcase}"
  end

  def conditions
    weather_data['text']
  end

  def title
    "#{weather_location['city']} Weather"
  end

  def call_api
    http = Net::HTTP.new('weather.yahooapis.com')
    response = http.request(Net::HTTP::Get.new("/forecastrss?w=#{woe_id}&u=#{format}"))
    response.body
  end

  def weather_data
    XmlSimple.xml_in(response_body, { 'ForceArray' => false })['channel']['item']['condition']
  end

  def weather_location
    XmlSimple.xml_in(response_body, { 'ForceArray' => false })['channel']['location']
  end

  def response_body
    @response_body ||= call_api
  end
end
