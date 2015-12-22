
require 'dizby/protocol/manager'
require 'dizby/converter/simple'
require 'dizby/worker/server'
require 'dizby/utility/log'

module Dizby
  class Service
    def initialize(uri = '', front = nil, config = {})
      config = DEFAULT_CONFIG.merge(config)

      self.server = ProtocolManager.open_server(uri, front, config)
    rescue NonAcceptingServer => err
      # This is to allow servers that don't accept connections
      # Not all servers will allow connections back to them, so don't allow it
      self.server = err.server
      @server.log.warn('using a server that does not allow connections')
    else
      @worker = ServiceWorker.new(@server)
    ensure
      Dizby.register_server(@server)
    end

    def connect_to(uri)
      ObjectProxy.new(*@server.connect_to(uri))
    end

    def spawn_on(command, uri)
      ObjectProxy.new(*@server.spawn_on(command, uri))
    end

    def close
      Dizby.unregister_server @server
      return unless alive?
      @server.shutdown
    end

    def alive?
      @server.alive?
    end

    def wait
      @worker.join if @worker
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
      fail DistributedError, 'server could not be opened' unless srvr
      @server = srvr
    end
  end
end
