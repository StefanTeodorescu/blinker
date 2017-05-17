#encoding: ASCII-8BIT
require 'net/http'
require 'uri'

require 'blinker/framework/capgen'

$host = ARGV[0]
$port = ARGV[1].to_i

def get_resp http, cookie=nil
  uri = URI("http://#{$host}:#{$port}/")
  req = Net::HTTP::Get.new uri
  req['Cookie'] = "userdata=#{cookie}" if cookie
  http.request req
end

if Random.rand > 0.10
  cookie = nil
  loop {
    Net::HTTP.start(ARGV.first, ARGV.last.to_i) do |http|
      base = get_resp http, cookie
      cookie = base['Set-Cookie']&.split(';')&.first&.split('=')&.last || cookie
      cookie = nil if Random.rand < 0.15
    end

    sleep 3+Random.rand*7
  }
else
  loop {
    Blinker::Framework::Capgen.with_webdriver do |drv|
      loop {
        drv.get("http://#{$host}:#{$port}/")

        break if Random.rand < 0.1
        sleep 1+Random.rand*4
      }
    end

    sleep 3+Random.rand*2
  }
end
