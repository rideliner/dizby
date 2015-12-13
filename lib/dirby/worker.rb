
module Dirby
  class ServiceWorker
    def initialize(server)
      @server = server
      @thread = Thread.start { run }
    end

    def join
      @thread.join if @thread
    end

    private

    def run
      connections = []
      loop do
        conn = accept_connection
        connections << conn if conn
      end
    rescue LocalServerShutdown
      @server.log.debug('Server shutdown')
    ensure
      @server.close if @server.alive?

      connections.each do |conn|
        conn.close
        conn.join
      end
    end

    def accept_connection
      connection = @server.accept
      return nil unless connection

      ConnectionWorker.new(@server, connection)
    end
  end

  class ConnectionWorker
    def initialize(server, conn)
      @server = server
      @conn = conn

      @server.add_uri_alias @conn.remote_uri

      @thread = Thread.start { process_requests }
    end

    def join
      # TODO: @thread gets set to nil for some reason...
      @thread.join if @thread
    end

    def close
      @conn.close unless @conn.closed?
    end

    private

    def process_requests
      loop { break unless process_request }
    rescue RemoteServerShutdown
      @server.log.debug("lost connection to server at #{@conn.remote_uri}")
    ensure
      @conn.close unless @conn.closed?
    end

    def process_request
      succ, result = InvokeMethod.new(@server, *@conn.recv_request).perform

      @server.log.backtrace(result) unless succ

      begin
        @conn.send_reply(succ, result)
      rescue
        @server.log.backtrace($!)
      end

      succ
    end
  end
end
