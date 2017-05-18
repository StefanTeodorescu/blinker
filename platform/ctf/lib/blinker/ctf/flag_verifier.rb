require 'blinker/ctf/job_runner'
require 'blinker/ctf/database_helper'

module Blinker
  module Ctf
    class FlagVerifier < JobRunner
      JOB_TYPE = 'verify_flag'

      def perform
        @db.transaction {
          ctf = @db.exec_params('SELECT * FROM ctfs WHERE uuid = $1::uuid AND flag_submission IS NOT NULL LIMIT 1 FOR UPDATE', [@uuid])

          if ctf.num_tuples > 0
            challenge, flag = ctf[0]['current_challenge'], ctf[0]['flag_submission']

            correct_flag = @db.exec_params('SELECT flag FROM ctfs JOIN ctf_challenges ON ctfs.current_challenge = ctf_challenges.id WHERE ctfs.uuid = $1::uuid LIMIT 1', [@uuid])

            if correct_flag.num_tuples > 0
              correct_flag = correct_flag[0]['flag']

              if flag == correct_flag
                @db.exec_params('INSERT INTO events_log (experiment, event) VALUES ($1::uuid, \'flag_accepted\')', [@uuid])
                DatabaseHelper.close_challenge @db, @uuid, challenge
              else
                @db.exec_params('INSERT INTO events_log (experiment, event) VALUES ($1::uuid, \'flag_rejected\')', [@uuid])
                @db.exec_params('UPDATE ctfs SET flag_submission = NULL WHERE uuid = $1::uuid', [@uuid])
              end
            else
              raise "no currently active flag recorded for ctf with uuid '#{@uuid}'"
            end
          end
        }
      end
    end
  end
end
