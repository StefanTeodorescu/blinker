require 'erb'
require 'shellwords'
require 'securerandom'

require 'blinker/ctf/job_runner'
require 'blinker/ctf/filestore_client'
require 'blinker/ctf/aptly_client'
require 'blinker/framework'
require 'blinker/utils/blank_binding'

module Blinker
  module Ctf
    class ChallengeGenerator < JobRunner
      JOB_TYPE = 'generate_challenge'

      def initialize *args
        super *args

        @challenges = Blinker::Framework::Challenges.new @settings[:challenges_dir]
        @filestore = Blinker::Ctf::FilestoreClient.new @settings[:filestore]
        @aptly = Blinker::Ctf::AptlyClient.new @settings[:aptly][:api]
      end

      def perform
        status = @challenges.generate @details, SecureRandom.hex(16)

        case status[:status]
        when :done
          handout =
            if status[:handout]
              @filestore.upload(@uuid, File.join(status[:dir],status[:handout]))
            else nil end
          package =
            if status[:deploy]
              deb = File.join(status[:dir],status[:deploy])
              pkgname = `dpkg-deb -W #{Shellwords.escape deb} Name | awk '{print $1}'`.strip
              raise "failed to determine package name of #{deb}" unless pkgname.length > 0

              @aptly.submit_package(deb, @settings[:aptly][:challenges_repo])
              pkgname
            else nil end

          erb = ERB.new status[:description]
          b = Blinker::Utils::BlankBinding.create
          b.local_variable_set :handout_url, handout
          message = erb.result b

          @db.transaction {
            @db.exec_params('INSERT INTO ctf_challenges (id, ctf, flag, handout, package, message) VALUES ($1::varchar(32), $2::uuid, $3::text, $4::text, $5::text, $6::text)', [status[:challenge_id], @uuid, status[:flag], handout, package, message])
          }
        when :started
          raise "Challenge generation was prematurely terminated: #{status[:dir]}"
        when :exception
          backtrace = status[:backtrace].map { |line| "\t#{line}" }.join
          cause = "#{status[:message]}\n#{backtrace}"
          raise "Challenge generation failed: #{status[:dir]}", cause: cause
        else
          raise "Failed to interpret challenge generation status: #{status.inspect}"
        end
      end
    end
  end
end
