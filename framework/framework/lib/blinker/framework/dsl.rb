require 'securerandom'
require 'shellwords'
require 'erb'
require 'ostruct'
require 'fpm'
require 'json'
require 'ipaddr'
require 'digest/sha2'

require 'blinker/utils/blank_binding'

module Blinker
  module Framework
    module DSL
      def random_bytes n
        SecureRandom.random_bytes n
      end

      def random_hex hexchars
        SecureRandom.hex(hexchars/2+1)[0...hexchars]
      end

      def random_number range
        SecureRandom.random_number range
      end

      def random_flag n=32
        random_n = n - 6
        raise 'flag entropy would be too low' if random_n < 8
        flag = "flag{#{SecureRandom.hex(random_n)}}"
        declare_flag flag
        flag
      end

      def declare_flag flag
        @flag = flag
      end

      def c_stack_padding range
        name_suffix = random_hex 10
        size = random_number(range) * 8
        %(char __blinker_padding_#{name_suffix}[#{size}] __attribute__((unused));)
      end

      def generated_file name_maybe_deps, &blk
        RakeDSL.file name_maybe_deps do |t|
          begin
            FileUtils.mkdir_p File.dirname(t.name)
            $stdout = File.open(t.name, 'w+')
            blk.call
          ensure
            $stdout.close
            $stdout = STDOUT
          end
        end
      end

      def erb_binding h
        @preprocess_binding = h
      end

      def erb_file h
        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        tasks = pairs.map { |output, sources|
          raise "preprocessed_file not expecting more than one prerequisite for a target (target #{output})" unless sources.one?
          source = sources.first

          generated_file output => [source] do
            erb = ERB.new(File.read source)
            erb.filename = source
            b = Blinker::Utils::BlankBinding.create
            (@preprocess_binding || {}).each { |k, v|
              v = v.call if v.respond_to? :call and v.respond_to? :arity and v.arity == 0
              b.local_variable_set k, v
            }
            print erb.result(b)
          end
        }

        (tasks.one?) ? tasks.first : tasks
      end

      def c_flags flags = {}
        flags = { flags => true } if flags.is_a? String or flags.is_a? Symbol
        @c_flags = flags
      end

      def c_compiled_no_preprocess h
        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        cc = 'clang'
        clang = []
        custom_passes = []
        opt = false
        llc = []
        link = ['-fuse-ld=lld']
        strip = false
        (@c_flags || {}).each { |key, value|
          case key
          when :stack_protector, :stackprotector
            case value
            when false, :no
              clang << '-fno-stack-protector'
            when true, :yes
              clang << '-fstack-protector'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :relro
            case value
            when false, :no, :none
              link << '-Wl,-z,norelro'
            when :partial
              link << '-Wl,-z,relro'
            when :full
              link << '-Wl,-z,relro,-z,now'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :nx, :dep
            case value
            when false, :no
              link << '-Wl,-z,execstack'
            when true, :yes
              link << '-Wl,-z,noexecstack'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :strip
            case value
            when false, :no
              strip = false
            when true, :yes
              strip = true
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :arch
            case value
            when :x86, :i386, :i686
              clang << '-m32'
              link << '-m32'
            when :x64, :x86_64, :amd64
              clang << '-m64'
              link << '-m64'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :pie
            case value
            when false, :no
              # placeholder
            when true, :yes
              clang << '-fPIE'
              llc += ['-relocation-model', 'pic']
              link << '-pie'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :O
            case value
            when 0, 1, 2, 3, 4
              opt = "-O#{value}"
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :debug
            case value
            when false, :no
              # placeholder
            when true, :yes
              clang << '-g'
              link << '-g'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :cc
            case value
            when 'clang', nil
              cc = 'clang'
            when 'clang++'
              cc = value
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :reorder_got_plt
            case value
            when false, :no
              # placeholder
            when true, :yes
              link << '-Wl,-randomize-got-plt'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :reorder_plt
            case value
            when false, :no
              # placeholder
            when true, :yes
              link << '-Wl,-randomize-plt'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :randomize_regs
            case value
            when false, :no
              # placeholder
            when true, :yes
              llc << '-randomize-regs'
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :randomize_branches
            case value
            when false, :no
              # placeholder
            when :conservative
              llc += ['-randomize-branches=conservative', '-fast-isel']
            when true, :yes, :reasonable
              llc += ['-randomize-branches=reasonable', '-fast-isel']
            when :aggressive
              llc += ['-randomize-branches=aggressive', '-fast-isel']
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :randomize_function_spacing
            case value
            when false, :no
              # placeholder
            when true, :yes
              llc += ['-randomize-fn-spacing', '48']
            when Integer
              llc += ['-randomize-fn-spacing', value.to_s]
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :randomize_scheduling
            case value
            when false, :no
              # placeholder
            when true, :yes
              llc += ['-misched', 'random']
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :reorder_functions
            case value
            when false, :no
              # placeholder
            when true, :yes
              custom_passes << ['-load', '/opt/blinker-llvm/lib/LLVMBlinker.so', '-reorder-functions']
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          when :reorder_globals
            case value
            when false, :no
              # placeholder
            when true, :yes
              custom_passes << ['-load', '/opt/blinker-llvm/lib/LLVMBlinker.so', '-reorder-globals']
            else
              raise "Unexpected value for #{key.inspect}: #{value.inspect}"
            end
          else
            raise "Unexpected C flag: #{key.inspect}"
          end
        }

        path = 'PATH=/opt/blinker-llvm/bin:$PATH'

        tasks = pairs.map { |output, sources|
          c_sources = sources.select { |source| ['.c', '.cpp', '.cxx'].any? { |ext| source.end_with? ext } }.map { |f|
            abs = File.absolute_path(f)
            uniq = File.basename(f) + '_' + Digest::SHA256.hexdigest(abs)
            [abs, uniq]
          }

          RakeDSL.file output => sources do
            commands = []
            objs = []

            c_sources.each { |s, u|
              bc = "./#{u}__blinker.bc"

              # compile C to LLVM IR
              commands << Shellwords.join([cc, '-emit-llvm', '-c'] + clang + ['-o', bc, s])

              # run any custom LLVM passes
              last = bc
              custom_passes.each_with_index { |pass, i|
                name = "./#{u}__blinker_opt#{i}.bc"
                commands << Shellwords.join(['opt'] + pass) + ' < ' + Shellwords.escape(last) + ' > ' + Shellwords.escape(name)
                last = name
              }

              # run an optimization pass
              if opt
                name = "./#{u}__blinker_optd.bc"
                commands << Shellwords.join(['opt', opt]) + ' < ' + Shellwords.escape(last) + ' > ' + Shellwords.escape(name)
                last = name
              end

              # compile LLVM IR to target bytecode
              obj = "./#{u}__blinker.o"
              objs << obj
              commands << Shellwords.join(['llc'] + llc + ['-filetype=obj', '-o', obj, last])
            }

            # link object file into executable
            objs = c_sources.map { |_, u| "./#{u}__blinker.o" }
            commands << Shellwords.join([cc] + link + ['-o', output] + objs)

            # strip symbols
            commands << Shellwords.join(['strip', output]) if strip

            # assemble & execute final command
            commands.map! { |cmd| "#{path} #{cmd}" }

            if BlinkerVars.debug
              puts "Commands about to be executed:"
              commands.each { |cmd| puts cmd }
              puts
            end

            command = commands.join(' && ')
            `#{command}`
            raise 'compilation failed' unless File.exists? output
          end
        }

        (tasks.one?) ? tasks.first : tasks
      end

      def c_compiled h
        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        tasks = pairs.map { |output, sources|
          preprocessed = []

          sources.each { |source|
            ext = ['.c', '.cpp', '.cxx'].detect { |ext| source.end_with? ext }
            if ext
              preproc_source = "#{source}__blinker_preprocessed#{ext}"
              preprocessed << preproc_source
              generated_file preproc_source => [source] do
                erb = ERB.new(File.read source)
                erb.filename = source
                puts "#define BLINKER_FRAMEWORK_PRESENT"
                print erb.result(binding)
              end
            else
              preprocessed << source
            end
          }

          c_compiled_no_preprocess output => preprocessed
        }
        (tasks.one?) ? tasks.first : tasks
      end

      def cxx_compiled h
        cc = (@c_flags ||= {})[:cc]
        c_flags :cc => 'clang++'
        tasks = c_compiled h
        c_flags :cc => cc
      end

      def tar_gz_archive h
        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        tasks = pairs.map { |output, sources|
          RakeDSL.file output => sources do |t|
            `#{Shellwords.join(['tar', '-C', File.absolute_path('.'), '-czf', output, '--'] + sources)}`
            raise 'failed to create archive' unless File.exists? output
          end
        }
        (tasks.one?) ? tasks.first : tasks
      end

      def deb_preinst script
        raise "wrong argument for deb_preinst: #{script.inspect}" unless script.is_a? String

        @deb_preinst = script
      end

      def deb_postinst script
        raise "wrong argument for deb_postinst: #{script.inspect}" unless script.is_a? String

        @deb_postinst = script
      end

      def deb_dependency dep
        raise "wrong argument for deb_dependency: #{dep.inspect}" unless dep.is_a? String or (dep.is_a? Array and dep.all? { |d| d.is_a? String })

        deps = [dep].flatten(1)

        (@deb_dependencies ||= []).concat deps
      end

      def deb_user user
        raise "wrong argument for deb_user: #{user.inspect}" unless user.is_a? String
        @deb_user = user
      end

      def deb_group group
        raise "wrong argument for deb_group: #{group.inspect}" unless group.is_a? String
        @deb_group = group
      end

      def deb_name name
        raise "wrong argument for deb_name: #{name.inspect}" unless name.is_a? String
        @deb_name = name
      end

      def deb_archive h
        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        tasks = pairs.map { |output, sources|
          RakeDSL.file output => sources do |t|
            pkg = FPM::Package::Dir.new
            pkg.name = @deb_name || raise('deb_name not set')
            pkg.version = '1.0'
            sources.each { |source| pkg.input(source) }
            pkg = pkg.convert(FPM::Package::Deb)
            pkg.scripts[:before_install] = @deb_preinst if @deb_preinst
            pkg.scripts[:after_install] = @deb_postinst if @deb_postinst
            pkg.attributes[:deb_user] = @deb_user if @deb_user
            pkg.attributes[:deb_group] = @deb_group if @deb_group
            pkg.dependencies = @deb_dependencies || []
            begin
              pkg.output(output)
            ensure
              pkg.cleanup
            end
          end
        }
        (tasks.one?) ? tasks.first : tasks
      end

      def network_capture h, &blk
        raise 'network_capture expects a block' unless blk

        pairs = (h.is_a? Hash) ? h.to_a : [[h.to_s, []]]
        pairs.map! { |output, sources| [output, [sources].flatten(1)] }

        tasks = []

        pairs.each { |output, sources|
          c = OpenStruct.new
          c.capture_name = output

          blk.call(c)

          raise 'hosts must be set to an array' unless c.hosts.is_a? Array
          raise 'capture_on must be set to a valid host id' unless c.capture_on.is_a? Fixnum and c.hosts[c.capture_on]

          topo = "#{output}_mininet.json"
          tasks << generated_file(topo) do |f|
            c.hosts.each_with_index { |h, i| h[:capture] = (c.capture_on == i) }
            puts({ :hosts => c.hosts, :mask => c.mask }.to_json)
          end

          tasks << RakeDSL.file(output => (sources+[topo])) do |t|
            FileUtils.mkdir_p File.dirname(t.name)
            sh "sudo /opt/blinker/capture.py < #{topo}"
            FileUtils.mv "h#{c.capture_on+1}.pcap", output
          end
        }

        (tasks.one?) ? tasks.first : tasks
      end

      def scenario sc
        raise "unknown scenario #{sc}" unless File.exists? File.join(__dir__, 'scenarios', "#{sc}.sc")
        import "#{sc}.sc"
      end

      extend self
    end
  end
end
