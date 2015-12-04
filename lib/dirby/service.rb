
require 'dirby/manager'
require 'dirby/converter'
require 'dirby/invoke'
require 'dirby/utility/log'

module Dirby
  class Service
    def initialize(uri = '', front = nil, config = {})
      config = DEFAULT_PRIMARY_CONFIG.merge(DEFAULT_CONFIG).merge(config)

      @server = ProtocolMgr.open_server(uri, front, config)
    rescue NonAcceptingServer => e
      # This is to allow servers that don't accept connections
      # Not all servers will allow connections back to them, so don't allow it. Period.
      @server = e.server
      @server.log.warn('using a server that does not allow connections') unless @server.nil?
    else
      @grp = ThreadGroup.new
      @thread = run
    ensure
      Dirby.register_server(@server) unless @server.nil?
    end

    def connect_to(uri)
      ObjectProxy.new(*@server.connect_to(uri))
    end

    def spawn_on(command, uri)
      ObjectProxy.new(*@server.spawn_on(command, uri))
    end

    # overrides the assumed defaults defined in DEFAULT_PRIMARY_CONFIG
    DEFAULT_CONFIG = {}

    def close
      unless @server.nil?
        Dirby.unregister_server @server
        @server.shutdown
      end
    end

    def alive?
      !@server.nil? && @server.alive?
    end

    def wait
      @thread.join unless @thread.nil?
    end

    private

    DEFAULT_PRIMARY_CONFIG = {
      idconv: IdConverter,
      argc_limit: 256,
      load_limit: 256 * 1024 * 100,
      logging: {
        verbosity: :error, # [:error, :info, :debug]
        output: $stderr
      },
      tcp_acl: nil
    }

    def run
      Thread.start do
        begin
          loop do
            conn_thread = main_loop
            @grp.add(conn_thread) unless conn_thread.nil?
          end
        rescue ServerShutdown
          @server.log.debug('Server shutdown')
        ensure
          @server.close unless alive?

          unless @grp.nil?
            @grp.enclose
            threads = @grp.list.delete_if(&:nil?)

            threads.each do |t|
              client = t[:dirby][:client]
              client.close unless client.closed?
            end
            threads.each(&:join)
          end

          @server = nil
          @grp = nil
        end
      end
    end

    def main_loop
      conn0 = @server.accept
      return nil if conn0.nil?

      Thread.start(conn0) do |conn|
        Thread.current[:dirby] = {
          client: conn,
          service: self,
          server: @server
        } # TODO: Is this really necessary?
        # client gets used when closing the server, the others aren't used at the moment.

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
      succ, result = invoke_method(*conn.recv_request)

      @server.log.backtrace(result) unless succ

      begin
        conn.send_reply(succ, result)
      rescue
        @server.log.backtrace($!)
      end

      succ
    end

    def invoke_method(*request)
      InvokeMethod.new(@server, *request).perform
    end
  end
end
