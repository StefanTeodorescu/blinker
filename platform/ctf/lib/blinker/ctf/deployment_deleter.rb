require 'blinker/ctf/job_runner'
require 'blinker/ctf/azure_client'

module Blinker
  module Ctf
    class DeploymentDeleter < JobRunner
      JOB_TYPE = 'delete_deployment'

      def initialize *args
        super *args

        @azure = Blinker::Ctf::AzureClient.new @settings[:azure]
      end

      def perform
        id = @details

        @db.transaction {
          challenge = @db.exec_params('SELECT package, deployment_state FROM ctf_challenges WHERE id = $1::varchar(32) FOR UPDATE', [id])
          raise "challenge with id #{id} does not exist" unless challenge.num_tuples > 0

          # if there is no deployable, don't bother
          next unless challenge[0]['package']

          case challenge[0]['deployment_state']
          when 'destroying', 'destroyed'
            # this is not necessarily a problem, as we no longer check for the deployment state in the trigger
          when 'failed'
            raise "challenge deployment state unexpected: #{challenge[0]['deployment_state']}"
          when 'none', 'initiated', 'deploying'
            throw :retry_seconds, 300
          end

          @db.exec_params('UPDATE ctf_challenges SET deployment_state = \'destroying\' WHERE id = $1::varchar(32)', [id])
        }

        @azure.delete id

        @db.exec_params('UPDATE ctf_challenges SET deployment_state = \'destroyed\' WHERE id = $1::varchar(32)', [id])
      end
    end
  end
end
