require 'blinker/framework/befunge/ast'

module Blinker
  module Refinements
    module DeepClone
      refine Object do
        def deep_clone
          return @deep_cloning_obj if @deep_cloning
          @deep_cloning_obj = clone
          @deep_cloning_obj.instance_variables.each do |var|
            val = @deep_cloning_obj.instance_variable_get(var)
            begin
              @deep_cloning = true
              val = val.deep_clone
            rescue TypeError
              next
            ensure
              @deep_cloning = false
            end
            @deep_cloning_obj.instance_variable_set(var, val)
          end
          deep_cloning_obj = @deep_cloning_obj
          @deep_cloning_obj = nil
          deep_cloning_obj
        end
      end
    end
  end
end

using Blinker::Refinements::DeepClone

module Blinker
  module Framework
    module Befunge
      class Backend
        def initialize
          @code = []
          @jumps = []
        end

        def emit code
          @code << code
          @code.length - 1
        end

        def jump from, to
          @jumps << [from, to]
        end

        def quote string
          "\"#{string}\""
        end

        def codegen_op block, op
          case op
          when CallOp
            # TODO do an actual call, don't just inline!

            inlined = block.blocks_referenced[op.block_referenced].deep_clone
            inlined.follow_operation = op.successor

            op.at = codegen_block inlined
          when ConstOp
            n = op.number

            if n >= 0 and n <= 9
              op.at = emit(n.to_s)
            elsif n >= 10 and n <= 18
              op.at = emit("9"+(n-9).to_s+"+")
            elsif n >= 19 and n <= 27
              op.at = codegen_op(block, ConstOp.new(nil, NumberArg.new(n-9)))
              emit '9+'
            elsif n >= 32 and n <= 127
              op.at = emit(quote(n.chr))
            else
              base9 = op.number.to_s(9).reverse
              op.at = emit base9
              emit('9*+' * (base9.length-1))
            end
          when IfZeroOp
            op.at = emit '!#'
            from = emit 'v_'
            jump from, op.conditional_successor
          when JmpOp
            op.at = emit 'v'
            jump op.at, op.successor
          when LoadOp
            var = block.variables[op.variable_referenced]
            x,y = var.coords

            op.at = codegen_op(block, ConstOp.new(nil, NumberArg.new(x)))
            codegen_op(block, ConstOp.new(nil, NumberArg.new(y)))
            emit 'g'
          when StoreOp
            var = block.variables[op.variable_referenced]
            x,y = var.coords

            op.at = codegen_op(block, ConstOp.new(nil, NumberArg.new(x)))
            codegen_op(block, ConstOp.new(nil, NumberArg.new(y)))
            emit 'p'
          when StringOp
            op.at = emit '0'
            emit quote(op.string.reverse)
          when AddOp
            op.at = emit '+'
          when DuplOp
            op.at = emit ':'
          when GtOp
            op.at = emit '`'
          when ModOp
            op.at = emit '%'
          when MulOp
            op.at = emit '*'
          when NegOp
            op.at = emit '!'
          when PopOp
            op.at = emit '$'
          when PrintAOp
            op.at = emit ','
          when ReadAOp
            op.at = emit '~'
          when RetOp
            # TODO proper return once non-inlined calls are available
            if block.follow_operation
              op.at = emit 'v'
              jump op.at, block.follow_operation
            else
              op.at = emit '@'
            end
          when SubOp
            op.at = emit '-'
          when SwapOp
            op.at = emit '\\'
          end

          op.at
        end

        def codegen_block block
          queue = [block.start]
          until queue.empty?
            op = queue.shift
            next if op.at
            codegen_op block, op
            queue.unshift op.conditional_successor if op.is_a? IfZeroOp
            queue.unshift op.successor if op.successor
          end
          block.start.at
        end

        def codegen main
          # allocate variables
          i = 0
          queue = [main]
          until queue.empty?
            block = queue.shift
            next if block.variables_referenced.all? { |var| block.variables[var].coords }

            queue += block.blocks_referenced.values
            block.variables_referenced.each { |var|
              var = block.variables[var]
              unless var.coords
                var.coords = [0, i]
                i += 1
              end
            }
          end
          variable_y_max = i

          # generate linear code
          codegen_block main

          # generate jumps
          jump_from = {}
          jump_to = Hash.new { |h, k| h[k] = [] }
          @jumps.each_with_index { |pair, i|
            from, to = pair
            jump_from[from] = i
            raise "unplaced instruction in generate jumps phase: #{to.inspect} (successor: #{to.successor.inspect}, at: #{to.successor&.at.inspect})" unless to.at
            jump_to[to.at] << i
          }

          # final placement
          outbuf = []
          offset = 1
          outbuf << ' ' # line 0 offset
          @code.each_with_index { |chunk, i|
            if jump_from[i]
              j = jump_from[i]
              @jumps[j][0] = offset
            end

            jump_to[i].each { |j|
              @jumps[j][1] = offset
              outbuf << '>'
              offset += 1
            }

            outbuf << chunk
            offset += chunk.length
          }
          outbuf << "\n"

          @jumps.each { |from, to|
            outbuf << (' ' * [from, to].min)
            outbuf << ((from < to) ? '>' : '^')
            outbuf << (' ' * ((from-to).abs-1))
            outbuf << ((from < to) ? '^' : '<')
            outbuf << (' ' * (offset - [from, to].max - 1))
            outbuf << "\n"
          }

          ([0,variable_y_max - @jumps.length].max).times {
            outbuf << ' ' * offset
            outbuf << "\n"
          }

          [offset+1, [variable_y_max, @jumps.length + 1].max, outbuf.join]
        end
      end
    end
  end
end
