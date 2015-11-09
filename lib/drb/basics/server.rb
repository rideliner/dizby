
require 'drb/manager'
require 'drb/delegate'
require 'drb/pipe'
require 'drb/util'

module DRb
  class BasicServer
    extend ClassicAttributeAccess

    def initialize(uri, front, stream, config)
      @config = config
      @uri = uri
      @front = front
      @stream = stream

      @exported_uri = [ @uri ]

      @shutdown_pipe = SelfPipe.new(*IO.pipe)
    end

    def close
      log('Closing')
      unless stream.nil?
        stream.close
        self.stream = nil
      end

      close_shutdown_pipe
    end

    def shutdown
      log('Shutting down')
      shutdown_pipe.close_write unless shutdown_pipe.nil?
    end

    def accept
      readables, = IO.select([stream, shutdown_pipe.read])
      raise ServerShutdown if readables.include? shutdown_pipe.read
      log('Accepting connection')
      stream.accept
    end

    def alive?
      return false if stream.nil?
      if IO.select([stream], nil, nil, 0)
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

    include Loggable
    extend Configurable

    attr_reader :uri
    config_reader :argc_limit, :load_limit, :verbose

    def log(msg)
      super "#{uri} : #{msg}"
    end

    def add_uri_alias(uri)
      log("Adding uri alias: #{uri}")

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
        log("making distributed: #{obj.inspect}")
        DistributedObject.new(obj, self)
      end
    end

    private

    config_reader :idconv, :debug
    attr_reader :front, :exported_uri
    attr_accessor :stream, :shutdown_pipe

    def close_shutdown_pipe
      unless shutdown_pipe.nil?
        log('Closing shutdown pipe')
        shutdown_pipe.close_read
        shutdown_pipe.close_write
        self.shutdown_pipe = nil
      end
    end
  end
end
