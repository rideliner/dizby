
require 'dirby/manager'
require 'dirby/utility/delegate'
require 'dirby/utility/pipe'
require 'dirby/utility/config'
require 'dirby/utility/log'

require 'io/wait'

module Dirby
  class BasicServer
    extend ClassicAttributeAccess

    def initialize(uri, front, stream, config)
      @config = config
      @uri = uri
      @front = front
      @stream = stream
      @log = Log.from_config(config[:logging], self)

      @exported_uri = [ @uri ]

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
      unless stream.ready?
        shutdown
        false
      end
      true
    end

    def connect_to(uri)
      ProtocolMgr.open_client(self, uri)
    end

    def to_obj(ref)
      return front if ref.nil?
      idconv.to_obj(ref)
    end

    def to_id(obj)
      return nil if obj.__id__ == front.__id__
      idconv.to_id(obj)
    end

    extend Configurable

    attr_reader :uri, :log
    config_reader :argc_limit, :load_limit

    def log_message(msg)
      "#{uri} : #{msg}"
    end

    def add_uri_alias(uri)
      log.debug("Adding uri alias: #{uri}")

      Rubinius.synchronize(exported_uri) {
        exported_uri << uri unless exported_uri.include?(uri)
      }
    end

    def here?(uri)
      Rubinius.synchronize(exported_uri) {
        exported_uri.include?(uri)
      }
    end

    def make_distributed(obj, error = false)
      if error
        RemoteDistributedError.new(obj)
      else
        log.debug("making distributed: #{obj.inspect}")
        DistributedObject.new(obj, self)
      end
    end

    private

    config_reader :idconv, :debug
    attr_reader :front, :exported_uri
    attr_accessor :stream, :shutdown_pipe

    def close_shutdown_pipe
      unless shutdown_pipe.nil?
        log.debug('Closing shutdown pipe')
        shutdown_pipe.close_read
        shutdown_pipe.close_write
        self.shutdown_pipe = nil
      end
    end
  end
end
