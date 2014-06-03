require 'net/http'
require 'json'

SCHEDULER.every '1h', :first_in => 0 do |job|
  projects = [
    { repo_id: '52e94af969568057bf002500', name: 'switchboard' },
    { repo_id: '538cd3cfe30ba0494a001c7d', name: 'fmp' },
  ]
  api_token = ENV['CODECLIMATE_API_TOKEN']

  projects.each do |project|
    repo_id = project[:repo_id]
    uri = URI.parse("https://codeclimate.com/api/repos/#{repo_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request.set_form_data({api_token: api_token})
    response = http.request(request)
    stats = JSON.parse(response.body)
    current_gpa = stats['last_snapshot']['gpa'].to_f

    if stats['previous_snapshot']
      last_gpa = stats['previous_snapshot']['gpa'].to_f
    else
      last_gpa = '4.0'
    end

    data_id = "code-climate-#{project[:name]}"
    send_event(data_id, {current: current_gpa, last: last_gpa})
  end
end
