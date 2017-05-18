#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'

# HACK of the year...
# this is used to work around an issue in rest-client
# https://github.com/rest-client/rest-client/issues/441
class UncloseableFile < File
  alias :really_close :close

  def close
    rewind
  end
end

if ARGV.first == 'clean' and ARGV.count == 4
  mode, host, port, repo = ARGV
elsif ARGV.first == 'add' and ARGV.count == 5
  mode, host, port, repo, deb = ARGV
else
  puts 'Usage:'
  puts 'Purges old package versions from the repo'
  puts "\t#{$0} clean <host> <port> <repo>"
  puts 'Adds a new package to the repo'
  puts "\t#{$0} add <host> <port> <repo> <deb>"
  exit 1
end

begin
  base = "http://#{host}:#{port}/"
  uri = URI(base)
rescue
  puts 'Malformed API URL'
  exit 1
end

version = begin
  Net::HTTP.get(uri + '/api/version')
rescue
  puts 'API sanity check failed: API endpoint unreachable'
  exit 1
end

begin
  JSON.parse(version)['Version'] =~ /[0-9.]+/
rescue
  puts 'API sanity check failed: unrecognized version'
  exit 1
end

if mode == 'clean'
  pkgdata = Net::HTTP.get(uri + "/api/repos/#{repo}/packages?format=details")
  keys = []

  JSON.parse(pkgdata).reduce({}) { |pkgs, pkg|
    (pkgs[pkg['Package']] ||= []) << [pkg['Version'],pkg['Key']]
    pkgs
  }.each { |p, vs|
    vs.sort_by!(&:first)
    dropping = (vs.length > 1) ? vs[0..-2].map(&:first).join(%(, )) : 'none'
    puts "#{p}: keeping #{vs.last.first}, dropping: #{dropping}"
    keys += vs[0..-2].map(&:last)
  }

  trap ('SIGINT') {
    puts 'Aborting'
    exit 0
  }

  puts "Go ahead? (Enter to continue, CTRL+C to quit)"
  $stdin.readline

  begin
    Net::HTTP.start(host, port.to_i) { |http|
      resp = http.send_request('DELETE', "/api/repos/#{repo}/packages", { 'PackageRefs' => keys }.to_json, { 'Content-Type' => 'application/json' }).body
      raise "unknown error (#{resp})" unless JSON.parse(resp) == {
        'Name' => repo,
        'Comment' => '',
        'DefaultDistribution' => '',
        'DefaultComponent' => 'main'
      }
      resp = http.send_request('PUT', "/api/publish/#{repo}/xenial", '{"ForceOverwrite": true}', { 'Content-Type' => 'application/json' }).body
      raise "unknown error (#{published})" unless JSON.parse(resp) == {
        'Architectures' => ['amd64'],
        'Distribution' => 'xenial',
        'Label' => '',
        'Origin' => '',
        'Prefix' => repo,
        'SkipContents' => false,
        'SourceKind' => 'local',
        'Sources' => [{'Component' => 'main', 'Name' => repo}],
        'Storage' => ''
      }
      puts 'Success'
    }
  rescue => e
    puts "Failed: #{e.message}"
    exit 1
  end
elsif mode == 'add'
  begin
    require 'rest-client'
  rescue LoadError
    puts 'You will need the rest-client gem:'
    puts 'gem install rest-client'
    exit 1
  end

  unless File.exists? deb
    puts "File '#{deb}' does not exist"
    exit 1
  end

  r = lambda { |response, request, result|
    case response.code
    when 307
      response.follow_redirection
    else
      response.return!
    end
  }

  begin
    file = UncloseableFile.new(deb)
    resp = RestClient.post(base+'/api/files/fs', file: file, &r)
    uploaded = JSON.parse(resp)
    raise 'API error' unless uploaded.is_a? Array
    raise "unknown error (#{resp})" unless uploaded.length == 1 and uploaded.first == "fs/#{File.basename(deb)}"
    uploaded = uploaded.first
    file.really_close
  rescue => e
    puts "Failed to upload file: #{e.message}"
    exit 1
  end

  puts 'Uploaded'

  begin
    resp = RestClient.post(base+"/api/repos/#{repo}/file/#{uploaded}?forceReplace=1",'', &r)
    added = JSON.parse(resp)
    raise 'API error' unless added.is_a? Hash and added['FailedFiles'].is_a? Array
    raise "unknown error (#{resp})" unless added['FailedFiles'].empty?
  rescue => e
    puts "Failed to add package to repo: #{e.message}"
    exit 1
  end

  puts 'Added to repo'

  begin
    resp = RestClient.put(base+"/api/publish/#{repo}/xenial", {'ForceOverwrite' => true}.to_json, content_type: :json, &r)
    published = JSON.parse(resp)
    raise "unknown error (#{resp})" unless published == {
      'Architectures' => ['amd64'],
      'Distribution' => 'xenial',
      'Label' => '',
      'Origin' => '',
      'Prefix' => repo,
      'SkipContents' => false,
      'SourceKind' => 'local',
      'Sources' => [{'Component' => 'main', 'Name' => repo}],
      'Storage' => ''
    }
  rescue => e
    puts "Failed to publish repo: #{e.message}"
    exit 1
  end

  puts 'Published'
else
  raise 'unknown command'
end
