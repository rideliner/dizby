
require 'dizby/worker/connection'

module Dizby
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

      connections.each(&:close)
    end

    def accept_connection
      connection = @server.accept
      return nil unless connection

      @server.add_uri_alias connection.remote_uri
      ConnectionWorker.new(@server, connection)
    end
  end
end
