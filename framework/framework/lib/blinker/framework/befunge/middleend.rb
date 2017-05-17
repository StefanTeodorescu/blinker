require 'blinker/framework/befunge/past'
require 'blinker/framework/befunge/ast'

module Blinker
  module Framework
    module Befunge
      class Middleend
        def self.translate past
          raise 'expected Program' unless past.is_a? Program
          program = past
          blocks = program.defs.map { |defi|
            raise 'expected Definition' unless defi.is_a? Definition
            insns = defi.insns
            raise 'expected an Array' unless insns.is_a? Array

            label_to_op = {}

            # translate to Operations
            ops = insns.map { |insn|
              raise 'expected an Instruction' unless insn.is_a? Instruction

              klass = {
                'add' => AddOp,
                'dupl' => DuplOp,
                'gt' => GtOp,
                'mod' => ModOp,
                'mul' => MulOp,
                'neg' => NegOp,
                'pop' => PopOp,
                'printa' => PrintAOp,
                'reada' => ReadAOp,
                'ret' => RetOp,
                'sub' => SubOp,
                'swap' => SwapOp,
                'call' => CallOp,
                'const' => ConstOp,
                'ifzero' => IfZeroOp,
                'jmp' => JmpOp,
                'load' => LoadOp,
                'store' => StoreOp,
                'string' => StringOp
              }[insn.oper]
              raise "unknown opcode #{insn.oper}" unless klass

              if insn.is_a? NullaryInstruction
                op = klass.new insn.label
              elsif insn.is_a? UnaryInstruction
                op = klass.new insn.label, insn.arg
              else
                raise 'expected a NullaryInstruction or a UnaryInstruction'
              end

              label_to_op[insn.label.identifier] = op if insn.label
              op
            }

            labels_referenced = ops.flat_map(&:labels_referenced).uniq
            variables_referenced = ops.flat_map(&:variables_referenced).uniq
            blocks_referenced = ops.select { |op| op.is_a? CallOp }.map { |op| op.block_referenced }.uniq

            #identifiers_reused = labels_referenced & variables_referenced
            #raise "the following identifiers are used as both labels and variables: #{identifiers_reused.join(', ')}"

            missing_labels = labels_referenced.reject { |label| label_to_op.has_key? label }
            raise "the following labels are not defined: #{missing_labels.join(', ')}" unless missing_labels.empty?

            ops.each_with_index { |op, i|
              if op.is_a? RetOp
                # has no successor
                next
              elsif op.is_a? JmpOp
                op.successor = label_to_op[op.label_referenced]
                next
              elsif op.is_a? IfZeroOp
                op.successor = ops[i+1]
                op.conditional_successor = label_to_op[op.label_referenced]
              else
                op.successor = ops[i+1]
              end

              raise "control flow reaches end of function at ##{i} (#{op.class}) in #{defi.name}" unless op.successor
            }

            block = Block.new defi.name, ops.first, blocks_referenced, variables_referenced, label_to_op
            [defi.name, block]
          }.to_h

          global_variables = Hash.new { |h, k| h[k] = Variable.new k }

          raise 'missing main block' unless blocks.has_key? 'main'

          blocks.each { |name, block|
            local_variables = Hash.new { |h, k| h[k] = Variable.new k }

            block.blocks_referenced, missing_blocks = block.blocks_referenced.map { |br| [br, blocks[br]] }.partition { |_, b| !b.nil? }.map(&:to_h)
            raise "#{name} references the following missing blocks: #{missing_blocks.join(', ')}" unless missing_blocks.empty?

            block.variables = block.variables_referenced.map { |name| [name, ((name.start_with? '$') ? global_variables : local_variables)[name]] }.to_h
          }

          main = blocks['main']
          queue = [main]
          until queue.empty?
            block = queue.shift
            block.blocks_referenced { |_, called|
              if called.caller
                cycle = [called]
                begin
                  cycle.unshift(cycle.first.caller)
                end until cycle.first == cycle.last
                raise "recursion detected! (#{cycle.join(' -> ')})"
              end

              called.caller = block
              queue.push called
            }
          end

          main
        end
      end
    end
  end
end
