require 'pg'

module Blinker
  module Utils
    class PostgresConnection
      def initialize *args
        @mutex = Mutex.new
        @failed_count = 0
        @conn = PG.connect *args

        ObjectSpace.define_finalizer(self, PostgresConnection.close_socket(@conn, Process.pid))
      end

      def method_missing *args, &blk
        # Sadly, Mutex is not reentrant, even thought it knows which thread it's held by
        if @mutex.owned?
          proxy_call *args, &blk
        else
          @mutex.synchronize { proxy_call *args, &blk }
        end
      end

      protected
      def proxy_call *args, &blk
        result = @conn.send *args, &blk
        @failed_count = 0
        result
      rescue PG::UnableToSend
        if failed_retry
          retry
        else
          raise
        end
      end

      def alive?
        @conn.status == PG::CONNECTION_OK && !@conn.finished?
      end

      def failed_retry
        @failed_count += 1

        case @failed_count
        when 1
          @conn.reset unless alive?
          true
        when 2
          sleep 0.1
          @conn.reset unless alive?
          true
        when 3
          sleep 0.5
          @conn.reset
          true
        when 4
          sleep 1
          @conn.reset
          true
        else
          false
        end
      end

      def self.close_socket conn, pid
        proc { IO.for_fd(conn.socket).close unless pid == Process.pid }
      end
    end
  end
end
