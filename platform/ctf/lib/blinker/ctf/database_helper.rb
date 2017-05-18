module Blinker
  module Ctf
    class DatabaseHelper
      def self.open_challenge db, ctf, challenge
        db.exec_params('UPDATE ctfs SET current_challenge = $2::varchar(32), challenge_requested = false WHERE uuid = $1::uuid', [ctf, challenge])
      end

      def self.close_challenge db, ctf, challenge
        current = DatabaseHelper.current_challenge db, ctf

        if current and current['id'] == challenge
          db.exec_params('UPDATE ctfs SET current_challenge = NULL, challenge_requested = false, skip_requested = false, flag_submission = NULL WHERE uuid = $1::uuid AND current_challenge = $2::varchar(32)', [ctf, challenge])
        else
          db.exec_params('UPDATE ctf_challenges SET state = \'used\'::ctf_challenge_state WHERE id = $1::varchar(32)', [challenge])
        end
      end

      def self.next_challenge db, ctf
        next_challenge = db.exec_params('SELECT * FROM ctf_challenges WHERE ctf = $1::uuid AND state = \'prepared\'::ctf_challenge_state ORDER BY generated_at ASC LIMIT 1 FOR UPDATE', [ctf])
        (next_challenge.num_tuples > 0) ? next_challenge[0] : nil
      end

      def self.current_challenge db, ctf
        current_challenge = db.exec_params('SELECT * FROM ctf_challenges WHERE ctf = $1::uuid AND state = \'current\'::ctf_challenge_state ORDER BY generated_at ASC LIMIT 1 FOR UPDATE', [ctf])
        (current_challenge.num_tuples > 0) ? current_challenge[0] : nil
      end

      def self.deploy_challenge db, id
        db.exec_params('UPDATE ctf_challenges SET deployment_state = \'initiated\' WHERE id = $1::varchar(32)', [id])
      end
    end
  end
end
