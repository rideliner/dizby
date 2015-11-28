
module Dirby
  class DistributedError < RuntimeError; end
  class ConnectionError < DistributedError; end
  class ServerNotFound < DistributedError; end
  class BadURI < DistributedError; end
  class BadScheme < DistributedError; end
  class ServerShutdown < DistributedError; end
  class RemoteShutdown < ConnectionError; end
  class SpawnError < DistributedError; end

  class NonAcceptingServer < DistributedError
    def initialize(server)
      @server = server
    end

    attr_reader :server
  end

  class RemoteDistributedError < DistributedError
    def initialize(error)
      @reason = error.class.to_s
      super("#{error.message} (#{error.class})")
      set_backtrace(error.backtrace)
    end

    attr_reader :reason
  end
end
