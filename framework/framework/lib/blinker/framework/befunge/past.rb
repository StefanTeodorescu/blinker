require 'rltk/ast'

module Blinker
  module Framework
    module Befunge
      class Arg
        def get
          @v
        end
      end

      class NumberArg < Arg
        def initialize n
          @v = n
        end
      end

      class StringArg < Arg
        def initialize s
          @v = s
        end
      end

      class IdentifierArg < Arg
        def initialize i
          @v = i
        end
      end

      class Label
        def initialize i
          @i = i
        end

        def identifier
          @i
        end
      end

      class Instruction < RLTK::ASTNode
        value :label, Label
        value :oper, String
      end

      class NullaryInstruction < Instruction
      end

      class UnaryInstruction < Instruction
        value :arg, Arg
      end

      class Definition < RLTK::ASTNode
        value :name, String
        child :insns, [Instruction]
      end

      class Program < RLTK::ASTNode
        child :defs, [Definition]
      end
    end
  end
end
