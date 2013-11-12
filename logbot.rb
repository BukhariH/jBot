require "json"
require "cinch"
require "redis"
require 'oj'
require 'net/http'


#Varibles
url = "http://api.bbcnews.appengine.co.uk/stories/headlines"
resp = Net::HTTP.get_response(URI.parse(url))
data = resp.body
json = Oj.load(data)
stories = json["stories"]
time = Time.new
now = time.strftime("%a %b %d")

#Methods
def nested_hash_value(obj, key)
  if obj.respond_to?(:key?) && obj.key?(key)
    obj[key]
  elsif obj.respond_to?(:each)
    r = nil
    obj.find{ |*a| r = nested_hash_value(a.last, key) }
    r
  end
end

def get_aww
  uri   = URI.parse('http://www.reddit.com/r/aww.json')
  resp  = Net::HTTP.get_response(uri)
  data  = Oj.load(resp.body)
  posts = data["data"]["children"].shuffle
  i     = 0

  posts.each do |c|
    if i < 1
      @cont = nested_hash_value(c, "url")
      i += 1
    end
  end

end

def get_wtf
  uri   = URI.parse('http://www.reddit.com/r/wtf.json')
  resp  = Net::HTTP.get_response(uri)
  data  = Oj.load(resp.body)
  posts = data["data"]["children"].shuffle
  i     = 0

  posts.each do |c|
    if i < 1
      @cont = nested_hash_value(c, "url")
      i += 1
    end
  end

end

def xkcd
xkcd_url = "http://xkcd.com/info.0.json"
xkcd_resp = Net::HTTP.get_response(URI.parse(xkcd_url))
xkcd_data = xkcd_resp.body
xkcd_json = Oj.load(xkcd_data)

"#{xkcd_json["title"]} - #{xkcd_json["img"]}"

end

def reddit_user(ruser)
ruser_url = "http://www.reddit.com/user/#{ruser}/about.json"
ruser_resp = Net::HTTP.get_response(URI.parse(ruser_url))
ruser_data = ruser_resp.body
ruser_json= Oj.load(ruser_data)

"Name: #{ruser_json["data"]["name"]} | Link Karma: #{ruser_json["data"]["link_karma"]} | Comment Karma: #{ruser_json["data"]["comment_karma"]} | Created at: #{Time.at(ruser_json["data"]["created"])} UTC"
end

channels = (ENV['LOGBOT_CHANNELS'] || '#bots,#teenagers,#programming,#lgbteens,#justchat,#Fitness,#peersupport').split /[\s,]+/
#channels = (ENV['LOGBOT_CHANNELS'] || '#bots,#test').split /[\s,]+/
redis = Redis.new(:thread_safe => true)

channels.each do |chan|
  redis.sadd("irclog:channels", "#{chan}")
end
#######################################################################
# => Configure
#######################################################################
bot = Cinch::Bot.new do
  configure do |conf|
    conf.server = (ENV['LOGBOT_SERVER'] || "irc.awfulnet.org")
    conf.nick = (ENV['LOGBOT_NICK'] || "Jbot")
    #conf.nick = (ENV['LOGBOT_NICK'] || "Jbot_Dev")
    conf.channels = channels
  end

  on :message do |msg|
    if not msg.channel.nil?
      date = msg.time.strftime("%Y-%m-%d")
      key = "irclog:channel:#{msg.channel.name}:#{date}"
      redis.rpush(key, {
        :time => "#{msg.time.strftime("%s.%L")}",
        :nick => "#{msg.user.nick}",
        :msg  => "#{msg.message}"
      }.to_json)
      redis.expire(key, 2592000)
    end
  end

    on :join do |msg|
    if not msg.channel.nil?
      date = msg.time.strftime("%Y-%m-%d")
      key = "irclog:channel:#{msg.channel.name}:#{date}"
      redis.rpush(key, {
        :time => "#{msg.time.strftime("%s.%L")}",
        :nick => "AwfulNet",
        :msg  => "#{msg.user.nick} just joined #{msg.message}"
      }.to_json)
      redis.expire(key, 2592000)
    end
  end

  on :leaving do |msg, user|
    if m.channel?
        if not msg.channel.nil?
        date = msg.time.strftime("%Y-%m-%d")
        key = "irclog:channel:#{msg.channel.name}:#{date}"
        redis.rpush(key, {
          :time => "#{msg.time.strftime("%s.%L")}",
          :nick => "AwfulNet",
          :msg  => "#{user} just left #{msg.channel}"
        }.to_json)
        redis.expire(key, 2592000)
      end
    else
      if not msg.channel.nil?
        date = msg.time.strftime("%Y-%m-%d")
        key = "irclog:channel:#{msg.channel.name}:#{date}"
        redis.rpush(key, {
          :time => "#{msg.time.strftime("%s.%L")}",
          :nick => "AwfulNet",
          :msg  => "#{user} just left the network."
        }.to_json)
        redis.expire(key, 2592000)
      end
    end
  end
  
  on :message, "$help" do |m|
    m.reply "$date - Gives you the date in GMT"
    m.reply "$news - Top three BBC Headlines"
    m.reply "$rand - 50/50 Game! 50% of the time r/aww and the other 50% r/wtf"
    m.reply "$xkcd - latest xkcd comic"
    m.reply "$rwhois - followed by a reddit username gives information about that user"
    m.reply "$log - Tells you where you can find the weblogs for the current channel."
  end



  on :message, /^\$rwhois (.+)/ do |m, ruser|
    m.reply(reddit_user(ruser) || "Jbot doesn't feel like talking", true)
  end

on :message, "$log" do |m|
    channeln = m.channel.name
    cn = channeln.tr('^A-Za-z0-9', '')
    m.reply "#{ENV['LOGURL']}/channel/#{cn}/today"
  end

on :message, "$xkcd" do |m|
    m.reply xkcd
  end

  on :message, "$date" do |m|
    m.reply "Hello, #{m.user.nick}! The date is: #{now} GMT!"
  end

  on :message, "$news" do |m|
    stories.first(3).each do |target_hash|
target_hash.first(1).each do |key, val|
  m.reply "#{val}"
end
end

  end

  on :message, "$rand" do |m|

chance = Random.new.rand(1..2) 
if chance == 1 
  get_aww
      m.reply "#{@cont.tr('"', '')}"
else
  get_wtf
      m.reply "#{@cont.tr('"', '')}"
end

  end

end
bot.start
