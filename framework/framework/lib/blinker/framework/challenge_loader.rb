module Blinker
  module Framework
    class ChallengeLoaderContext
      include Rake::DSL
      include Blinker::Framework::DSL
    end

    class ChallengeLoader
      def load filename
        @context ||= ChallengeLoaderContext.new
        filename = File.join(__dir__, 'scenarios', filename) if File.extname(filename) == '.sc'
        @context.instance_eval(File.read(filename), filename, 1)
      end

      def flag
        @context&.instance_variable_get(:@flag) || raise('no flag declared')
      end
    end
  end
end
