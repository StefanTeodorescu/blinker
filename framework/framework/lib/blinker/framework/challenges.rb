require 'tmpdir'
require 'json'
require 'shellwords'
require 'ostruct'

require 'blinker/framework/dsl'
require 'blinker/framework/load_rake'
require 'blinker/framework/challenge_loader'

module Blinker
  module Framework
    class Challenges
      def initialize directory
        pattern = File.absolute_path(File.join(directory, '/*/*.chall'))
        @challenges = Dir.glob(pattern).map { |file|
          challenge_name = File.basename(File.dirname(file)).split('_').map(&:capitalize).join
          [challenge_name, file]
        }.to_h
      end

      def names
        @challenges.keys
      end

      def generate name, id, opts = {}
        chall_file = @challenges[name]
        raise "unknown challenge: #{name}" unless chall_file

        tempdir = Dir.mktmpdir 'blinker-'

        Dir.glob("#{File.dirname(chall_file)}/*") { |entry|
          FileUtils.cp_r entry, tempdir
        }

        status_file = File.absolute_path(File.join(tempdir, '__blinker_status'))

        Process.wait fork {
          build_status = { :status => :started, :dir => tempdir, :challenge_id => id }

          Dir.chdir tempdir
          File.write(status_file, build_status.to_json)

          Object.const_set 'BlinkerVars', OpenStruct.new
          BlinkerVars.challenge_id = id
          BlinkerVars.debug = (opts[:debug]) ? true : false

          begin
            ARGV.clear
            ARGV.concat ['--rakefile', File.join(__dir__, 'challenge.rake'),
                         '--no-search',
                         '--silent']

            Rake.application = app = Rake::Application.new
            loader = ChallengeLoader.new
            app.add_loader '.chall', loader
            app.add_loader '.sc', loader
            app.add_import chall_file
            app.init 'blinker'
            app.load_rakefile

            handout = app['handout'] rescue nil
            deploy = app['deploy'] rescue nil

            raise 'no handout and no deployable' unless handout or deploy

            description = app['description'] rescue nil
            raise 'no challenge description' unless description&.sources&.one?

            if handout
              task = handout
              if task.sources.length > 1
                task = DSL.tar_gz_archive '__blinker_handout.tar.gz' => task.sources
              elsif task.sources.empty?
                raise 'empty handout list specified'
              end

              task.invoke
              build_status[:handout] = task.sources.first
            end

            if deploy
              unless deploy.sources.one? and File.extname(deploy.sources.first) == '.deb'
                raise 'the deployable must be a single .deb file'
              end

              deploy.invoke

              deb = deploy.sources.first
              pkgname = `dpkg-deb -W #{Shellwords.escape deb} Name | awk '{print $1}'`.strip

              raise "the deployable package must be named 'blinker-challenge-#{id}', but instead it was named '#{pkgname}'" unless pkgname == "blinker-challenge-#{id}"

              build_status[:deploy] = deb
            end

            description.invoke
            build_status[:description] = File.read description.sources.first

            build_status[:flag] = loader.flag

            save = [build_status[:handout], build_status[:deploy], '__blinker_status'].compact

            unless opts[:debug]
              Dir.glob(File.join(tempdir, "/*")).reject { |entry|
                save.include? File.basename(entry)
              }.each { |entry|
                FileUtils.remove_entry_secure entry
              }
            end

            build_status[:status] = :done
          rescue => e
            build_status.merge! status: :exception, message: e.message, backtrace: e.backtrace
          ensure
            File.write(status_file, build_status.to_json)
          end
        }

        status = JSON.parse(File.read(status_file)) rescue raise('failed to read build status file')
        status = status.to_a.map { |k,v| [k.to_sym, v] }.to_h.merge(status: status['status'].to_sym)
        raise 'failed to interpret build status' unless [:started, :exception, :done].include? status[:status]
        status
      end
    end
  end
end
