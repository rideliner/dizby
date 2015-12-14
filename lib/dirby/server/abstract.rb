
require 'dirby/protocol/manager'
require 'dirby/distributed/object'
require 'dirby/utility/configurable'
require 'dirby/utility/log'

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
      ProtocolManager.open_client(self, uri)
    end

    def spawn_on(command, uri)
      ProtocolManager.spawn_server(self, command, uri)
    end

    def shutdown; end

    def alive?
      true
    end

    def make_distributed(obj, error)
      if error
        RemoteDistributedError.new(obj)
      else
        log.debug("making distributed: #{obj.inspect}")
        DistributedObject.new(obj, self)
      end
    end
  end
end
