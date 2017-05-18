require 'blinker/utils/config_file'

cfg = Blinker::Utils::ConfigFile.new 'filestore', :default_path => File.join(__dir__, '../../config.yml')
# must be done before sinatra/base is loaded
ENV['RACK_ENV'] = cfg[:environment] if cfg[:environment] and ENV['RACK_ENV'].nil?

raise "uploads directory '#{cfg[:upload_dir]}' does not exist" unless Dir.exists? cfg[:upload_dir]
raise "insufficient permissions on uploads directory '#{cfg[:upload_dir]}'" unless [:readable?, :writable?, :executable?].all? { |p| File.send(p, cfg[:upload_dir]) }

raise "exceptions directory '#{cfg[:exceptions_dir]}' does not exist" unless Dir.exists? cfg[:exceptions_dir]
raise "insufficient permissions on exceptions directory '#{cfg[:exceptions_dir]}'" unless File.writable? cfg[:exceptions_dir]

require 'blinker/utils/exception_logger'
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'securerandom'
require 'fileutils'
require 'json'
require 'socket'

$cfg = cfg
$exception_logger = Blinker::Utils::ExceptionLogger.new(cfg[:exceptions_dir])

module Blinker
  module Filestore
    class App < Sinatra::Base
      configure :development do
        register Sinatra::Reloader
      end

      $cfg.each { |key, value|
        set key.to_sym, value
      }

      error do
        $exception_logger.log env, env['sinatra.error']

        'An unexpected error occurred. It was logged, and some poor soul was dispatched to look at it.'
      end

      set :layout, :layout
      set :root, File.join(__dir__, '../..')
      set :static, false

      set :provision_ip, Socket.ip_address_list.detect { |ip| ip.ipv4_private? }.ip_address
      set :provision_pubkey, File.read($cfg[:pubkey])

      get '/ping' do
        'pong'
      end

      get '/handout/:name' do
        path = File.expand_path("#{settings.upload_dir}/#{params[:name]}")
        pass unless File.file?(path) and File.readable?(path)

        cache_control :public
        send_file path, type: 'application/octet-stream', disposition: :attachment
      end

      get '/provision' do
        ip = settings.provision_ip
        pubkey = settings.provision_pubkey

        erb :provision, locals: { :ip => ip, :pubkey => pubkey }
      end

      post '/upload' do
        halt 400, 'no file' unless params[:file]

        name = "#{SecureRandom.urlsafe_base64 32}_#{params[:file][:filename]}"
        halt 400, 'name too long' unless name.length <= 128

        path = File.join(settings.upload_dir, name)

        FileUtils.mv params[:file][:tempfile], path

        json result: :ok, filename: name
      end
    end
  end
end

