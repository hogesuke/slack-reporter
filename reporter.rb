require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'date'
require 'pp'

class Reporter

  def initialize
    @token = ENV['SLACK_API_TOKEN']
  end

  def run
    channels = fetch_channels

    histories = {}
    channels.each do |c|
      histories[c['id']] = fetch_history(c)
    end

    # pp histories

    user_ids = []
    histories.each do |ch_id, history|
      user_ids << history['messages'].select{ |m| !m['user'].nil? }.map{ |m| m['user'] }
    end
    user_ids.flatten!.uniq!
    # pp user_ids

    users = fetch_users(user_ids)
    user_names = {}
    users.map{ |u| user_names[u['id']] = u['name'] }

    template = File.read(File.join(__dir__, './templates/main.erb'))
    html = ERB.new(template).result(binding)

    File.write(File.join(__dir__, "./contents/#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.html"), html)
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

  def fetch_history(channel)
    url = URI.parse("https://slack.com/api/channels.history?token=#{@token}&channel=#{channel['id']}&count=2")
    puts 'start history request'
    res = Net::HTTP.get(url)
    puts 'end history request'

    JSON.parse(res)
  end

end

reporter = Reporter.new
reporter.run