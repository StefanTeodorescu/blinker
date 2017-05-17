require 'erb'

# Loosely based on Rack::MailExceptions

module Blinker
  module Utils
    class ExceptionLogger
      def initialize dir
        @dir = dir
        @template = ERB.new(TEMPLATE)

        raise "exception log directory '#{dir}' not found" unless Dir.exists? dir
        raise "exception log directory '#{dir}' must writable" unless File.writable? dir
      end

      def log env, exception
        time = Time.now
        report = @template.result binding

        id = 1

        begin
          name = "#{time.strftime('%Y%m%d-%H%M%S')}-#{Process.pid}"
          name += "-#{id}" if id > 1
          File.open(File.join(@dir, name), File::WRONLY|File::CREAT|File::EXCL) { |f|
            f.write report
          }
        rescue Errno::EEXIST
          id += 1
          retry
        end
      end

      protected
      def extract_body(env)
        if io = env['rack.input']
          io.rewind if io.respond_to?(:rewind)
          io.read
        end
      end

      TEMPLATE = (<<-'REPORT').gsub(/^ {8}/, '')
        Time: <%= time %>
        A <%= exception.class.to_s %> occured: <%= exception.to_s %>
        ===================================================================
        Rack Environment:
        ===================================================================
          PID:                     <%= $$ %>
          PWD:                     <%= Dir.getwd %>
          <%= env.to_a.
            sort{|a,b| a.first <=> b.first}.
            map do |k,v|
              if k == 'HTTP_AUTHORIZATION' and v =~ /^Basic /
                v = 'Basic *filtered*'
             end
              "%-25s%p" % [k+':', v]
            end.
            join("\n  ") %>
        <% if exception.respond_to?(:backtrace) %>
        ===================================================================
        Backtrace:
        ===================================================================

          <%= exception.backtrace.join("\n  ") %>
        <% end %>
        <% if body = extract_body(env) %>
        ===================================================================
        Request Body:
        ===================================================================
        <%= (body.length > 8192 || body =~ /[^[:print:][:space:]]/) ? body : body.gsub(/^/, '  ') %>
        <% end %>
        REPORT
    end
  end
end
