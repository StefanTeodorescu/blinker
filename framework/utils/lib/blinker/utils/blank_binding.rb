module Blinker
  module Utils
    class BlankBinding
      def self.create
        binding
      end
    end
  end
end
