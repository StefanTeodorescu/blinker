require 'securerandom'

module Blinker
  module Web
    class Experiment
      attr_reader :uuid
      @@priv_db ||= @@anon_db ||= nil

      def self.setup priv_db, anon_db
        @@priv_db ||= priv_db
        @@anon_db ||= anon_db
      end

      protected
      def initialize hash
        raise 'Experiment#setup must be called first' unless anon_db and priv_db

        case hash.keys
        when [:email]
          @uuid = SecureRandom.uuid
          email = hash[:email]

          priv_db.exec_params("INSERT INTO tokens (uuid, email, experiment_kind) VALUES ($1::uuid, $2::varchar(100), '#{kind}'::experiment_kind)", [@uuid, email])
          anon_db.exec_params("INSERT INTO tokens (uuid, experiment_kind) VALUES ($1::uuid, '#{kind}'::experiment_kind)", [@uuid])
        when [:uuid]
          # TODO consider simply returning nil instead of throwing exceptions, or at least throw something other than RuntimeError
          @uuid = extract_uuid hash[:uuid]
          raise 'malformed uuid' unless @uuid

          exp = anon_db.exec_params('SELECT experiment_kind FROM tokens WHERE uuid = $1::uuid', [uuid])
          raise 'invalid uuid' unless exp.num_tuples == 1 and exp[0]['experiment_kind'] == kind
        else
          raise NoMethodError
        end
      end

      private
      def kind
        self.class.name.gsub(/\A.+::([^:]+)\z/,'\1').downcase
      end

      def priv_db
        @@priv_db
      end

      def anon_db
        @@anon_db
      end

      def extract_uuid string
        (string =~ /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/) && $~[0]
      end
    end
  end
end
