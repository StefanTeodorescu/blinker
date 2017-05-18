require 'erb'

require 'blinker/ctf/job_runner'
require 'blinker/ctf/azure_client'

module Blinker
  module Ctf
    class ChallengeDeployer < JobRunner
      JOB_TYPE = 'deploy_challenge'

      def initialize *args
        super *args

        @azure = Blinker::Ctf::AzureClient.new @settings[:azure]
      end

      def perform
        id = @details

        @db.transaction {
          challenge = @db.exec_params('SELECT package, deployment_state FROM ctf_challenges WHERE id = $1::varchar(32) FOR UPDATE', [id])
          raise "challenge with id #{id} does not exist" unless challenge.num_tuples > 0
          raise "no package registered for challenge with id #{id}" unless challenge[0]['package']
          raise "challenge deployment state unexpected: #{challenge[0]['deployment_state']}" unless challenge[0]['deployment_state'] == 'initiated'

          @db.exec_params('UPDATE ctf_challenges SET deployment_state = \'deploying\' WHERE id = $1::varchar(32)', [id])
        }
        deploy = @azure.deploy id, @settings[:azure][:provision_script]

        state = nil
        while deploy.in_progress?
          new_state = deploy.state

          if state != new_state
            state = new_state

            @db.exec_params('INSERT INTO events_log (experiment, event, message, info) VALUES ($1::uuid, \'deployment_update\', $2::text, json_build_object(\'challenge\', $3::text))', [@uuid, state.to_s, id])
          end

          deploy.wait 15
        end

        if deploy.succeeded?
          @db.exec_params('UPDATE ctf_challenges SET deployment_state = \'deployed\', deployed_to = $2::text WHERE id = $1::varchar(32)', [id, deploy.domain])
        else
          @db.exec_params('UPDATE ctf_challenges SET deployment_state = \'failed\' WHERE id = $1::varchar(32)', [id])
          raise deploy.reason
        end
      end
    end
  end
end
