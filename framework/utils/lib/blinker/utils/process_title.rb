require 'fiddle'

module Blinker
  module Utils
    class ProcessTitle
      # adapted from http://stackoverflow.com/a/10523684
      def self.set title
        Process.setproctitle title
        $0 = title

        return unless RUBY_PLATFORM.split('-')[1] == 'linux'

        Fiddle::Function.new(
          Fiddle::Handle['prctl'], [
            Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP,
            Fiddle::TYPE_LONG, Fiddle::TYPE_LONG,
            Fiddle::TYPE_LONG
          ], Fiddle::TYPE_INT
        ).call(15, title, 0, 0, 0)
      end
    end
  end
end
