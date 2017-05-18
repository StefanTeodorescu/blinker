require 'yaml'
require 'pg'
require 'socket'

require 'blinker/utils/process_title'
require 'blinker/utils/postgres_connection'

module Blinker
  module Ctf
    class JobRunner
      def initialize settings
        raise "JOB_TYPE not defined in #{self.class.name}" unless defined? self.class::JOB_TYPE

        @worker_id = "#{Socket.gethostname}_#{Process.pid}_#{Time.now.to_i}"
        Blinker::Utils::ProcessTitle.set "blinker-ctf worker: #{@worker_id}"

        @settings = settings

        @db = Blinker::Utils::PostgresConnection.new @settings[:db]
        @db.exec('LISTEN ctf_jobs')

        @uuid, @id, @details = nil, nil, nil
        @exit_requested = false

        Signal.trap('TERM', &method(:interrupted))
        Signal.trap('INT', &method(:interrupted))
      end

      def run
        job_type = self.class::JOB_TYPE

        loop {
          return if @exit_requested

          @db.transaction { |db|
            jobs = db.exec_params('SELECT id, uuid, details FROM ctf_jobs_scheduling WHERE type = $1::ctf_job_type AND status = \'waiting\' ORDER BY schedule_at ASC LIMIT 1 FOR UPDATE', [job_type])

            if jobs.num_tuples > 0
              @id = jobs[0]['id']
              @uuid = jobs[0]['uuid']
              @details = jobs[0]['details']
              db.exec_params('UPDATE ctf_jobs SET status = \'inprogress\', worker = $2::text WHERE id = $1::integer', [@id, @worker_id])
            end
          }

          if @uuid
            begin
              retry_in = catch(:retry_seconds) { perform; nil }
              if retry_in.is_a? Numeric
                @db.exec_params('UPDATE ctf_jobs SET status = \'waiting\', not_before = now() + make_interval(secs => $2::double precision), worker = NULL WHERE id = $1::integer', [@id, retry_in.to_f])
              else
                @db.exec_params('UPDATE ctf_jobs SET status = \'completed\' WHERE id = $1::integer', [@id])
              end
            rescue => exception
              cause = exception.cause
              description = "Exception: #{exception.class} - #{exception.message}\n#{exception.backtrace.join("\n")}"
              if cause
                if cause.is_a? Exception
                  description += "\nCaused by: #{cause.class} - #{cause.message}\n#{cause.backtrace.join("\n")}"
                else
                  description += "\nCaused by: #{cause.inspect}"
                end
              end

              @db.exec_params('UPDATE ctf_jobs SET status = \'failed\', result = $2::text WHERE id = $1::integer', [@id, description])
            ensure
              @uuid, @id, @details = nil, nil, nil
            end
          else
            @db.wait_for_notify(10)
          end
        }
      end

      protected
      def interrupted _
        if @id
          # job selected, should wait for it to complete
          # there is a small probability that we could still abort the db transaction, but the complexity of checking for that far outweighs the gain
          @exit_requested = true
        else
          # even if a job is selected, it certainly has not yet been marked selected, so we are free to quit
          exit
        end
      end
    end
  end
end
