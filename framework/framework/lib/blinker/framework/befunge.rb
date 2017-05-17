require 'blinker/framework/befunge/frontend'
require 'blinker/framework/befunge/middleend'
require 'blinker/framework/befunge/backend'

module Blinker
  module Framework
    module Befunge
      def self.compile_ir ir
        tokens = Lexer.lex ir
        past = Parser.parse tokens
        ast = Middleend.translate past
        width, height, playfield = Backend.new.codegen ast
      end
    end
  end
end
