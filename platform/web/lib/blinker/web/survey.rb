require_relative 'experiment.rb'

module Blinker
  module Web
    class Survey < Experiment
      def response_submitted?
        result = anon_db.exec_params('SELECT COUNT(*) FROM survey_responses WHERE uuid = $1::uuid', [@uuid])
        result[0]['count'] != '0'
      end

      def submit_response answers
        result = anon_db.exec_params('INSERT INTO survey_responses (uuid, response) VALUES ($1::uuid, $2::jsonb)', [@uuid, answers])
      end
    end
  end
end
