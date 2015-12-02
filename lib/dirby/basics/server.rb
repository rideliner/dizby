
require 'dirby/manager'
require 'dirby/ref'
require 'dirby/utility/delegate'
require 'dirby/utility/pipe'
require 'dirby/utility/config'
require 'dirby/utility/log'

require 'io/wait'

module Dirby
  class AbstractServer
    extend Configurable

    def initialize(config, &log_transform)
      @config = config
      @log = Dirby.create_logger(config[:logging], &log_transform)
    end

    attr_reader :log
    config_reader :load_limit

    def connect_to(uri)
      ProtocolMgr.open_client(self, uri)
    end

    def spawn_on(command, uri)
      ProtocolMgr.spawn_server(self, command, uri)
    end

    def shutdown; end

    def alive?
      true
    end

    def make_distributed(obj, error = false)
      if error
        RemoteDistributedError.new(obj)
      else
        log.debug("making distributed: #{obj.inspect}")
        DistributedObject.new(obj, self)
      end
    end
  end

  class BasicServer < AbstractServer
    extend ClassicAttributeAccess

    def initialize(uri, front, stream, config)
      super(config) { |msg| "#{uri} : #{msg}" }

      @uri = uri
      @front = front
      @stream = stream

      @exported_uri = [@uri]

      @shutdown_pipe = SelfPipe.new(*IO.pipe)
    end

    def close
      log.debug('Closing')
      unless stream.nil?
        stream.close
        self.stream = nil
      end

      close_shutdown_pipe
    end

    def shutdown
      log.debug('Shutting down')
      shutdown_pipe.close_write unless shutdown_pipe.nil?
    end

    def accept
      readables, = IO.select([stream, shutdown_pipe.read])
      raise ServerShutdown if readables.include? shutdown_pipe.read
      log.debug('Accepting connection')
      stream.accept
    end

    def alive?
      return false if stream.nil?
      return true if stream.ready?

      shutdown
      false
    end

    def to_obj(ref)
      case ref
      when nil
        front
      when QueryRef
        front[ref.to_s]
      else
        idconv.to_obj(ref)
      end
    end

    def to_id(obj)
      return nil if obj.__id__ == front.__id__
      idconv.to_id(obj)
    end

    attr_reader :uri
    config_reader :argc_limit

    def add_uri_alias(uri)
      log.debug("Adding uri alias: #{uri}")

      Rubinius.synchronize(exported_uri) do
        exported_uri << uri unless exported_uri.include?(uri)
      end
    end

    def here?(uri)
      Rubinius.synchronize(exported_uri) { exported_uri.include?(uri) }
    end

    private

    config_reader :idconv
    attr_reader :front, :exported_uri
    attr_accessor :stream, :shutdown_pipe

    def close_shutdown_pipe
      return nil if shutdown_pipe.nil?

      log.debug('Closing shutdown pipe')
      shutdown_pipe.close_read
      shutdown_pipe.close_write
      self.shutdown_pipe = nil
    end
  end
end
