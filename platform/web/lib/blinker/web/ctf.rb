require_relative 'experiment.rb'

module Blinker
  module Web
    class CTF < Experiment
      def events since = '0'
        events = anon_db.exec_params('SELECT id,event,message,challenge FROM ctf_events WHERE uuid = $1::uuid AND id > $2::integer ORDER BY id ASC', [uuid, since])
        events.values.map { |row| events.fields.zip(row).to_h }
      end

      def completed?
        completion = anon_db.exec_params('SELECT ended_at IS NOT NULL AS completed FROM ctfs WHERE uuid = $1::uuid', [@uuid])
        return false unless completion.num_tuples > 0
        completion[0]['completed'] == 't'
      end

      def started?
        start = anon_db.exec_params('SELECT COUNT(*) FROM ctfs WHERE uuid = $1::uuid', [@uuid])
        return false unless start.num_tuples > 0
        start[0]['count'].to_i > 0
      end

      def submit_flag flag
        anon_db.exec_params('UPDATE ctfs SET flag_submission = $2::text WHERE uuid = $1::uuid', [@uuid, flag])
      end

      def skip
        anon_db.exec_params('UPDATE ctfs SET skip_requested = true WHERE uuid = $1::uuid', [@uuid])
      end

      def proceed
        anon_db.transaction {
          ctf = anon_db.exec_params('SELECT * FROM ctfs WHERE uuid = $1::uuid FOR UPDATE', [@uuid])

          if ctf.num_tuples == 0
            anon_db.exec_params('INSERT INTO ctfs (uuid) VALUES ($1::uuid) ON CONFLICT DO NOTHING', [@uuid])
            ctf = anon_db.exec_params('SELECT * FROM ctfs WHERE uuid = $1::uuid FOR UPDATE', [@uuid])
          end

          if ctf[0]['current_challenge'].nil?
            anon_db.exec_params('UPDATE ctfs SET challenge_requested = true WHERE uuid = $1::uuid', [@uuid])
          end
        }
      end

      def job_queues
        q = 'WITH user_jobs AS (
                SELECT type, min(schedule_at) AS start
                FROM ctf_jobs_scheduling
                WHERE uuid = $1::uuid AND status = \'waiting\'
                  AND type IN (\'verify_flag\', \'generate_challenge\', \'deploy_challenge\', \'direct_ctf\')
                GROUP BY type
              )
          SELECT type, count(id)-1 AS position
          FROM ctf_jobs_scheduling AS all_jobs
          WHERE schedule_at <= (SELECT start FROM user_jobs WHERE user_jobs.type = all_jobs.type)
            AND schedule_at < now() - interval \'5 seconds\'
            AND all_jobs.status = \'waiting\'
          GROUP BY all_jobs.type;'

        queues = anon_db.exec_params(q, [@uuid])
        queues.map { |row| { :type => row['type'], :position => row['position'].to_i } }
      end

      def current_challenge
        ctf = anon_db.exec_params('SELECT current_challenge FROM ctfs WHERE uuid = $1::uuid', [@uuid])
        return nil unless ctf.num_tuples > 0
        ctf[0]['current_challenge']
      end

      CHALLENGE_DESCRIPTIONS = {
        'ReNormalize' => 'Password encoded in control flow',
        'AmazingRop' => 'Maze escape by ROP',
        'SimpleBof' => 'Buffer overflow greeting service',
        'Mysecuresite' => 'Padding oracle PCAP forensics',
        'HommageAIrc' => 'Format string injection char service',
        'Refunge' => 'Befunge VM and the Chinese Remainder Theorem'
      }

      def stats
        challs = anon_db.exec_params('SELECT * FROM ctf_stats($1::uuid)', [@uuid])
        challs.map { |chall|
          challenge = CHALLENGE_DESCRIPTIONS[chall['challenge']] ||
                      CHALLENGE_DESCRIPTIONS[chall['challenge'].gsub(/^Static/,'')] ||
                      'no description'
          { 'challenge' => challenge, 'minutes' => chall['minutes'], 'skipped' => chall['skipped'] == 't' }
        }
      end
    end
  end
end
