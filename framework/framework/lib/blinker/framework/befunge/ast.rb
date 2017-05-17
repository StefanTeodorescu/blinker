module Blinker
  module Framework
    module Befunge
      class Operation
        attr_reader :label
        attr_accessor :successor
        attr_accessor :at

        def initialize label
          @label = label
        end

        def labels_referenced
          []
        end

        def variables_referenced
          []
        end
      end

      class NullaryOperation < Operation
      end

      class NumOperation < Operation
        def initialize label, n
          super label

          raise 'expected a NumberArg' unless n.is_a? NumberArg
          @n = n.get.to_i
        end

        def number
          @n
        end
      end

      class StringOperation < Operation
        def initialize label, s
          super label

          raise 'expected a StringArg' unless s.is_a? StringArg
          @s = s.get
        end

        def string
          @s
        end
      end

      class LabelOperation < Operation
        def initialize label, l
          super label

          raise 'expected an IdentifierArg' unless l.is_a? IdentifierArg
          @l = l.get
        end

        def labels_referenced
          [@l]
        end

        def label_referenced
          @l
        end
      end

      class StorageOperation < Operation
        def initialize label, v
          super label

          raise 'expected an IdentifierArg' unless v.is_a? IdentifierArg
          @v = v.get
        end

        def variables_referenced
          [@v]
        end

        def variable_referenced
          @v
        end
      end

      class CallOp < Operation
        def initialize label, d
          super label

          raise 'expected an IdentifierArg' unless d.is_a? IdentifierArg
          @d = d.get
        end

        def block_referenced
          @d
        end
      end

      class ConstOp < NumOperation
      end

      class IfZeroOp < LabelOperation
        attr_accessor :conditional_successor
      end

      class JmpOp < LabelOperation
      end

      class LoadOp < StorageOperation
      end

      class StoreOp < StorageOperation
      end

      class StringOp < StringOperation
      end

      class AddOp < NullaryOperation
      end

      class DuplOp < NullaryOperation
      end

      class GtOp < NullaryOperation
      end

      class ModOp < NullaryOperation
      end

      class MulOp < NullaryOperation
      end

      class NegOp < NullaryOperation
      end

      class PopOp < NullaryOperation
      end

      class PrintAOp < NullaryOperation
      end

      class ReadAOp < NullaryOperation
      end

      class RetOp < NullaryOperation
        def successor
          nil
        end

        def successor= _
          raise 'RetOp has no successor'
        end
      end

      class SubOp < NullaryOperation
      end

      class SwapOp < NullaryOperation
      end

      class Block
        attr_reader :name
        attr_reader :start
        attr_accessor :blocks_referenced
        attr_reader :variables_referenced
        attr_accessor :variables
        attr_reader :labels
        attr_accessor :caller
        attr_accessor :follow_operation

        def initialize name, start, blocks_refd, vars_refd, labels
          @name, @start = name, start
          @blocks_referenced = blocks_refd
          @variables_referenced = vars_refd
          @labels = labels
        end
      end

      class Variable
        attr_reader :name
        attr_accessor :coords

        def initialize name
          @name = name
        end
      end
    end
  end
end
