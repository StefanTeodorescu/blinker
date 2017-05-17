require 'rltk/lexer'
require 'rltk/parser'

require 'blinker/framework/befunge/past'

module Blinker
  module Framework
    module Befunge
      class Lexer < RLTK::Lexer
        class Environment < Environment
          def push_char ch
            (@str ||= []) << ch
            nil
          end

          def get_string
            str = @str.join
            @str = []
            str
          end
        end

        r(/\s/)

        r(/def/)	{ :DEFBLOCK }
        r(/end/)  { :ENDBLOCK }

        r(/:/) { :COLON }
        r(/\(/) { :LPAREN }
        r(/\)/) { :RPAREN }
        r(/\+/) { :PLUS }
        r(/-/) { :MINUS }

        r(/"/) { push_state :string }
        r(/"/, :string) { pop_state; [:STR, get_string] }
        r(/\\/, :string) { push_state :stringescape }
        r(/./, :string) { |c| push_char(c) }
        r(/x[0-9a-f]{2}/, :stringescape) { |m| pop_state; push_char(m[1..2].to_i(16).chr) }
        r(/n/, :stringescape) { pop_state; push_char("\n") }
        r(/t/, :stringescape) { pop_state; push_char("\t") }
        r(/\\/, :stringescape) { pop_state; push_char("\\") }
        r(/"/, :stringescape) { pop_state; push_char("\"") }

        r(/[0-9]+/) { |num| [:NUM, num] }
        r(/'[[:ascii:]]'/) { |char| [:NUM, char[1].ord] }

        r(/;/) { push_state :comment }
        r(/\n/, :comment) { pop_state }
        r(/./, :comment)

        %w(add dupl gt mod mul neg pop printa reada ret sub swap).each { |inst|
          r(/#{inst}/) { [:NULLARY, inst] }
        }

        %w(call const ifzero jmp load store string).each { |inst|
          r(/#{inst}/) { [:UNARY, inst] }
        }

        r(/[_$A-Za-z][_A-Za-z0-9]*/) { |id| [:IDENT, id] }
      end

      class Parser < RLTK::Parser
        production(:program, 'def*') { |defs| Program.new defs }
        production(:def, 'DEFBLOCK IDENT lbld_insn* ENDBLOCK') { |_, name, is, _| Definition.new name, is }
        production(:lbld_insn, 'label? insn') { |l, i| i.tap { |i| i.label = l } }
        production(:insn) do
          clause('NULLARY') { |i| NullaryInstruction.new nil, i }
          clause('UNARY argument') { |i, a| UnaryInstruction.new nil, i, a }
        end
        production(:argument) do
          clause('STR') { |s| StringArg.new s }
          clause('IDENT') { |i| IdentifierArg.new i }
          clause('expr') { |e| NumberArg.new e }
        end
        production(:label, 'IDENT COLON') { |i, _| Label.new i }
        production(:expr) do
          clause('LPAREN expr PLUS expr RPAREN') { |_, e1, _, e2, _| e1 + e2 }
          clause('LPAREN expr MINUS expr RPAREN') { |_, e1, _, e2, _| e1 - e2 }
          clause('NUM') { |n| n }
        end

        finalize
      end
    end
  end
end
