
require 'dirby/manager'
require 'dirby/converter'
require 'dirby/invoke'
require 'dirby/utility/log'

module Dirby
  class Service
    def initialize(uri = '', front = nil, config = {})
      config = DEFAULT_CONFIG.merge(config)

      self.server = ProtocolMgr.open_server(uri, front, config)
    rescue NonAcceptingServer => err
      # This is to allow servers that don't accept connections
      # Not all servers will allow connections back to them, so don't allow it
      self.server = err.server
      @server.log.warn('using a server that does not allow connections')
    else
      @thread = run
    ensure
      Dirby.register_server(@server)
    end

    def connect_to(uri)
      ObjectProxy.new(*@server.connect_to(uri))
    end

    def spawn_on(command, uri)
      ObjectProxy.new(*@server.spawn_on(command, uri))
    end

    def close
      return unless @server
      Dirby.unregister_server @server
      @server.shutdown
    end

    def alive?
      @server && @server.alive?
    end

    def wait
      @thread.join if @thread
    end

    DEFAULT_CONFIG = {
      idconv: IdConverter,
      argc_limit: 256,
      load_limit: 256 * 1024 * 100,
      logging: {
        level: Logger::ERROR,
        output: $stderr
      },
      tcp_acl: nil
    }

    private

    def server=(srvr)
      raise DistributedError, 'server could not be opened' unless srvr
      @server = srvr
    end

    def run
      Thread.start do
        grp = ThreadGroup.new
        begin
          loop do
            conn_thread = main_loop
            grp.add(conn_thread) if conn_thread
          end
        rescue ServerShutdown
          @server.log.debug('Server shutdown')
        ensure
          @server.close unless alive?
          self.class.close_clients(grp)

          @server = nil
        end
      end
    end

    def self.close_clients(grp)
      grp.enclose.list.each do |thr|
        # TODO: why are threads getting set to nil?
        next unless thr
        client = thr[:dirby][:client]
        client.close unless client.closed?
        thr.join
      end
    end

    def main_loop
      connection = @server.accept
      return nil unless connection

      Thread.start(connection) do |conn|
        Thread.current[:dirby] = {
          client: conn,
          service: self,
          server: @server
        } # TODO: Is this really necessary?
        # client gets used when closing the server
        # the others aren't used at the moment.

        @server.add_uri_alias conn.remote_uri

        process_requests(conn)
      end
    end

    def process_requests(conn)
      loop { break unless process_request(conn) }
    rescue ServerShutdown
      @server.log.debug("server shutdown, closed connection to #{conn.remote_uri}")
    rescue RemoteShutdown
      @server.log.debug("remote connection closed to #{conn.remote_uri}")
    ensure
      conn.close unless conn.closed?
    end

    def process_request(conn)
      succ, result = InvokeMethod.new(@server, *conn.recv_request).perform

      @server.log.backtrace(result) unless succ

      begin
        conn.send_reply(succ, result)
      rescue
        @server.log.backtrace($!)
      end

      succ
    end
  end
end
