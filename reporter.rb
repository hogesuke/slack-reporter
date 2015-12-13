require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'date'

class Reporter

  def initialize
    @token = ENV['SLACK_API_TOKEN']
  end

  def run
    channels = fetch_channels
    histories = fetch_history(channels)

    # histories.each do |h|
    #   puts h['messages']
    # end

    user_ids = histories.map do |h|
      h['messages'].map{ |m| m['user'] }
    end
    user_ids.flatten!.uniq!

    users = fetch_users(user_ids)
    user_names = {}
    users.map{ |u| p u; p user_names; user_names[u['id']] = u['name'] }

    template = File.read(File.join(__dir__, './templates/main.erb'))
    html = ERB.new(template).result(binding)

    File.write(File.join(__dir__, "./out/#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.html"), html)
  end

  def fetch_channels()
    url = URI.parse("https://slack.com/api/channels.list?token=#{@token}")
    res = Net::HTTP.get(url)
    channels = JSON.parse(res)

    channels['channels'].select{ |c| c['is_channel'] && c['is_member'] && !c['is_archived'] }
  end

  def fetch_users(user_ids)
    users = []
    user_ids.each do |id|
      url = URI.parse("https://slack.com/api/users.info?token=#{@token}&user=#{id}")
      puts 'start user request'
      res = Net::HTTP.get(url)
      puts 'end user request'
      users << JSON.parse(res)
    end

    users.select{ |u| !u['user'].nil? }.map{ |u| u['user'] }
  end

  def fetch_history(channels)
    histories = []
    channels.each do |c|
      url = URI.parse("https://slack.com/api/channels.history?token=#{@token}&channel=#{c['id']}&count=2")
      puts 'start history request'
      res = Net::HTTP.get(url)
      puts 'end history request'
      histories << JSON.parse(res)
    end

    histories
  end

end

reporter = Reporter.new
reporter.run