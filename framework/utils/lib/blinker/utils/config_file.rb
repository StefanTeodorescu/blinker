require 'yaml'

require 'blinker/utils/symbolic_hash'

module Blinker
  module Utils
    class ConfigFile
      def initialize component, options = {}
        default_path = options[:default_path]

        env_var = "BLINKER_#{component.upcase}_CONFIGFILE"
        path = ENV[env_var] || default_path

        unless File.readable? path
          raise "The config file #{path} could not be read. You can override this path using the environment variable #{env_var}."
        end

        config = YAML.load_file(path)

        raise "invalid configuration file" unless config.is_a? Hash

        @config = SymbolicHash.wrap config
      end

      def [] key
        @config[key]
      end

      def each *args, &blk
        @config.each(*args, &blk)
      end
    end
  end
end
