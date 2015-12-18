require 'json'
require 'net/http'
require 'uri'
require 'erb'
require 'date'
require 'time'
require 'pp'

class Reporter

  def initialize
    @token = ENV['SLACK_API_TOKEN']
    @start_time = ARGV[0]
    @end_time = ARGV[1]
  end

  def run
    time_range = get_time_range(@start_time, @end_time)

    channels = fetch_channels

    histories = {}
    channels.each do |c|
      histories[c['id']] = fetch_history(c, time_range)
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

  def fetch_history(channel, time_range)
    url = URI.parse("https://slack.com/api/channels.history?token=#{@token}&channel=#{channel['id']}&oldest=#{time_range[:start_time]}&latest=#{time_range[:end_time]}")
    puts 'start history request'
    res = Net::HTTP.get(url)
    puts 'end history request'

    JSON.parse(res)
  end

  def get_time_range(start_time_str, end_time_str)

    time_regexp = /([01][0-9]|2[0-4])[0-5][0-9]/

    unless start_time_str =~ time_regexp and end_time_str =~ time_regexp
      fail 'start_time, end_timeは4桁の数字で時刻を入力してください。'
    end

    unless start_time_str.to_i <= 2400 and end_time_str.to_i <= 2400
      fail '2400より大きい時刻の指定はできません。'
    end

    start_time_str = start_time_str[0..1] + ':' + start_time_str[2..3]
    end_time_str   = end_time_str[0..1] + ':' + end_time_str[2..3]

    start_time    = Time.parse(start_time_str)
    end_time      = Time.parse(end_time_str)
    a_day_seconds = 24 * 60 * 60

    if end_time > Time.now
      start_time = start_time - a_day_seconds
      end_time = end_time - a_day_seconds
    end

    if start_time > end_time
      start_time = start_time - a_day_seconds
    end

    if start_time == end_time
      start_time = start_time - a_day_seconds
    end

    { :start_time => start_time.to_i, :end_time => end_time.to_i }
  end

end

reporter = Reporter.new
reporter.run