require 'blinker/ctf/job_runner'
require 'blinker/ctf/database_helper'

module Blinker
  module Ctf
    class DeadlineEnforcer < JobRunner
      JOB_TYPE = 'enforce_deadline'

      def perform
        @db.transaction {
          DatabaseHelper.close_challenge @db, @uuid, @details
        }
      end
    end
  end
end
