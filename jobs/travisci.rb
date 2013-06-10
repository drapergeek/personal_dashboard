require 'travis'
require 'travis/pro'

def build_info(repository, config)
  repo = nil

  if config["type"] == "pro"
    Travis::Pro.access_token = config["auth_token"]
    repo = Travis::Pro::Repository.find(repository)
  else  # Standard namespace
    Travis.access_token = ENV['TRAVIS_AUTH_TOKEN']
    repo = Travis::Repository.find(repository)
  end

  build = repo.last_build
  {
    branch: "Build #{build.number}",
    value: "#{build.branch_info}",
    duration_state: "#{build.state} in #{build.duration}s"
  }
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/travisci.yml'
config = YAML::load(File.open(config_file))

SCHEDULER.every('2m', first_in: '1s') do
  config.each do |type, type_config|
    unless type_config["repositories"].nil?
      type_config["repositories"].each do |data_id, repo|
        send_event(data_id, build_info(repo, type_config))
      end
    else
      puts "No repositories for travis.#{type}"
    end
  end
end
