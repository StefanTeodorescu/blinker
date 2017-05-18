require 'blinker/utils/config_file'

cfg = Blinker::Utils::ConfigFile.new 'web', :default_path => File.join(__dir__, '../../config.yml')
# must be done before sinatra/base is loaded
ENV['RACK_ENV'] = cfg[:environment] if cfg[:environment] and ENV['RACK_ENV'].nil?

raise "exceptions directory '#{cfg[:exceptions_dir]}' does not exist" unless Dir.exists? cfg[:exceptions_dir]
raise "insufficient permissions on exceptions directory '#{cfg[:exceptions_dir]}'" unless File.writable? cfg[:exceptions_dir]

require 'blinker/utils/exception_logger'
require 'blinker/utils/postgres_connection'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/json'
require 'sinatra/reloader'
require 'haml'
require 'pony'
require 'json'

require 'blinker/web/ctf'
require 'blinker/web/survey'

$cfg = cfg
$exception_logger = Blinker::Utils::ExceptionLogger.new(cfg[:exceptions_dir])

# TODO we might need csrf countermeasures on at least the signup pages
module Blinker
  module Web
    class App < Sinatra::Base
      # Email format verification is controversial, this will do here
      EMAIL_REGEX = /\A[^@]+@[a-z\d\-]+(\.[a-z\d\-]+)*\z/i

      configure :development do
        register Sinatra::Reloader
      end

      $cfg.each { |key, value|
        set key.to_sym, value
      }

      error do
        $exception_logger.log env, env['sinatra.error']

        haml :error
      end

      set :layout, :layout
      set :root, File.join(__dir__, '../..')
      set :public_folder, File.join(__dir__, '../../public')
      set :views, File.join(__dir__, '../../views')

      priv_db = Blinker::Utils::PostgresConnection.new settings.priv_db
      anon_db = Blinker::Utils::PostgresConnection.new settings.anon_db
      Experiment.setup priv_db, anon_db

      Pony.options = settings.mail
      Pony.override_options = { :via => :test } if development?

      get '/' do
        haml :index
      end

      not_found do
        status 404
        @title = 'Not found'
        haml :index
      end

      get '/survey' do
        pass unless params[:token] == settings.survey_token

        @title = 'Survey'
        haml :survey_form
      end

      post '/survey' do
        pass unless params[:token] == settings.survey_token
        halt haml(:survey_form, locals: { :email => params[:email], :email_invalid => true }) unless params[:email] =~ EMAIL_REGEX

        begin
          survey = Survey.new :email => params[:email]

          Pony.mail :to => params[:email], :subject => 'Survey', :body => erb(:email, layout: false, locals: { :uuid => survey.uuid, :experiment => 'survey' })
        rescue PG::UniqueViolation
        end

        @title = 'Survey'
        @genre = 'experiment'
        haml :emailed
      end

      get '/survey/participate' do
        survey = Survey.new :uuid => params[:uuid] rescue pass

        pass if survey.response_submitted?

        @title = 'Survey'
        haml :survey
      end

      post '/survey/participate' do
        answers = params[:answers]

        begin
          JSON.parse(answers) # try and parse as JSON to fail earlier if malformed
        rescue
          status 400
          next json(:result => :fail)
        end

        survey = Survey.new :uuid => params[:uuid] rescue pass

        survey.submit_response(answers)

        json :result => :ok
      end

      get '/ctf' do
        pass unless params[:token] == settings.ctf_token

        @title = 'Trial CTF competition'
        haml :ctf_form
      end

      post '/ctf' do
        pass unless params[:token] == settings.ctf_token
        halt haml(:ctf_form, locals: { :email => params[:email], :email_invalid => true }) unless params[:email] =~ EMAIL_REGEX

        begin
          ctf = CTF.new :email => params[:email]

          Pony.mail :to => params[:email], :subject => 'Trial CTF competition', :body => erb(:email, layout: false, locals: { :uuid => ctf.uuid, :experiment => 'ctf' })
        rescue PG::UniqueViolation
        end

        @title = 'Trial CTF competition'
        @genre = 'competition'
        haml :emailed
      end

      get '/ctf/participate' do
        ctf = CTF.new :uuid => params[:uuid] rescue pass

        if request.xhr?
          if ctf.completed?
            since = params[:since] || '0'
            json :status => 'completed',
                 :events => ctf.events(since)
          elsif ctf.started?
            since = params[:since] || '0'
            json :status => 'started',
                 :events => ctf.events(since),
                 :queues => ctf.job_queues
          else
            json :status => 'ready'
          end
        else
          @completed = ctf.completed?
          @stats = ctf.stats
          @allow_skip = settings.allow_skip
          @title = 'Trial CTF competition'
          haml :ctf
        end
      end

      post '/ctf/participate' do
        ctf = CTF.new :uuid => params[:uuid] rescue pass

        if params[:flag]
          ctf.submit_flag(params[:flag])
        elsif params[:skip] and settings.allow_skip
          ctf.skip
        else
          ctf.proceed
        end

        json :result => :ok
      end
    end
  end
end
