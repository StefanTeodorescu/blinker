require 'blinker/ctf/job_runner'
require 'blinker/ctf/database_helper'

module Blinker
  module Ctf
    class CtfDirector < JobRunner
      JOB_TYPE = 'direct_ctf'

      def perform
        @db.transaction {
          ctf = @db.exec_params('SELECT * FROM ctfs WHERE uuid = $1::uuid FOR UPDATE', [@uuid])
          raise "ctf not found: #{@uuid}" unless ctf.num_tuples > 0

          # runs whenever:
          #  - the current challenge is closed (current_challenge is set to NULL)
          #  - a challenge is requested by the user (challenge_requested is set)
          #  - the user requests to skip the current challenge (skip_requested is set)
          #  - a challenge is generated

          next_challenge = DatabaseHelper.next_challenge @db, @uuid

          if ctf[0]['challenge_requested'] == 't' and next_challenge
            # if a challenge was requested and there is one available, assign it
            DatabaseHelper.open_challenge @db, @uuid, next_challenge['id']
          elsif ctf[0]['skip_requested'] == 't'
            # if the user requested to skip the current challenge, do so
            DatabaseHelper.close_challenge @db, @uuid, ctf[0]['current_challenge']
          end

          to_generate = @db.exec_params('SELECT ctf_pick_next_challenge($1::uuid) AS next', [@uuid]).first['next']

          need_more = !to_generate.nil?
          current_challenge = DatabaseHelper.current_challenge @db, @uuid
          next_challenge = DatabaseHelper.next_challenge @db, @uuid

          # the current challenge should be deployed

          if current_challenge and current_challenge['package'] and current_challenge['deployment_state'] == 'none'
            DatabaseHelper.deploy_challenge @db, current_challenge['id']
          end

          # if there is no current challenge, there is no prepared challenge,
          # and there will not be any more challenges generated, we have to stop
          # the experiment

          unless current_challenge or next_challenge or need_more
            @db.exec_params('UPDATE ctfs SET ended_at = now() WHERE uuid = $1::uuid AND ended_at IS NULL', [@uuid]);
          end

          # we should always have one challenge ready (generated & deployed)
          # unless this is the last challenge

          if next_challenge.nil?
            if need_more
              # there will be a next challenge, but it is not yet generated
              # if the generation of a challenge is already pending, we do not start another one
              @db.exec_params('UPDATE ctfs SET challenge_pending = $2::text WHERE uuid = $1::uuid and challenge_pending IS NULL', [@uuid, to_generate])
            end
          else
            if next_challenge['package'] and next_challenge['deployment_state'] == 'none'
              # the next challenge has been generated, but not yet deployed
              DatabaseHelper.deploy_challenge @db, next_challenge['id']
            end
          end
        }
      end
    end
  end
end
