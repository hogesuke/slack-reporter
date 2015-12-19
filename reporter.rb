require 'json'
require 'net/http'
require 'openssl'
require 'uri'
require 'erb'
require 'date'
require 'time'
require 'pp'

class Reporter

  def initialize
    @token = ENV['SLACK_API_TOKEN']
    @user = ENV['SLACK_USER']

    if @token.nil?
      fail 'SLACK_API_TOKENを環境変数に登録してください。'
    end
    if @user.nil?
      fail 'SLACK_USERを環境変数に登録してください。'
    end

    if ARGV.size == 2
      @time_range = get_time_range(start_time_str: ARGV[0], end_time_str: ARGV[1])
    elsif ARGV.size == 1
      @time_range = get_time_range(minutes_str: ARGV[0])
    else
      fail "取得するメッセージの時間範囲、または、何分前からのメッセージを取得するか指定してください。\n" +
               "ex. reporter.rb 0900 1800  #9:00 - 18:00 のメッセージを取得\n" +
               "ex. reporter.rb 120        # 2時間前からのメッセージを取得"

    end
  end

  def run
    channels = fetch_channels

    histories = {}
    channels.each do |c|
      histories[c['id']] = fetch_history(c, @time_range)
    end

    user_ids = []
    histories.each do |ch_id, history|
      user_ids << history['messages'].select{ |m| !m['user'].nil? }.map{ |m| m['user'] }
    end
    user_ids.flatten!.uniq!

    users = fetch_users(user_ids)
    user_names = {}
    users.map{ |u| user_names[u['id']] = u['name'] }

    template = File.read(File.join(__dir__, './templates/main.erb'))
    html     = ERB.new(template).result(binding)
    path     = File.join(__dir__, "contents/#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.html")

    File.write(path, html)

    post_report(@user, 'file://' + path)
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
      res = Net::HTTP.get(url)
      users << JSON.parse(res)
    end

    users.select{ |u| !u['user'].nil? }.map{ |u| u['user'] }
  end

  def fetch_history(channel, time_range)
    url = URI.parse("https://slack.com/api/channels.history?token=#{@token}&channel=#{channel['id']}&oldest=#{time_range[:start_time]}&latest=#{time_range[:end_time]}&count=1000")
    res = Net::HTTP.get(url)

    JSON.parse(res)
  end

  def get_time_range(start_time_str: nil, end_time_str: nil, minutes_str: nil)

    if minutes_str
      minutes_regexp = /[1-9][0-9]*/

      unless minutes_str =~ minutes_regexp
        fail 'minutesは1以上の数字を入力してください。'
      end

      time_now   = Time.now
      start_time = time_now - minutes_str.to_i * 60
      end_time   = time_now
    else
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
    end

    { :start_time => start_time.to_i, :end_time => end_time.to_i }
  end

  def post_report(user_name, path)
    message = "`#{path}` にレポートが作成されました。"

    url = URI.parse(URI.escape("https://slack.com/api/chat.postMessage?token=#{@token}&channel=#{'@' + user_name}&text=#{message}&username=SlackReporter"))
    req = Net::HTTP::Post.new(url.request_uri)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http.start do |h|
      h.request(req)
    end
  end

end

reporter = Reporter.new
reporter.run