
require 'dirby/basics'
require 'dirby/error'
require 'dirby/util'

module Dirby
  class DeadProtocol
    include BasicProtocol

    self.scheme = ''

    self.regex = /^$/

    def self.open_server(_, config)
      raise NonAcceptingServer, Server.new(config)
    end

    class Server
      def initialize(config)
        @config = config
      end

      def shutdown; end
      def alive?; true; end

      include Loggable
      extend Configurable

      # A DeadProtocol server doesn't allow backwards connections
      # therefore, making a distributed object goes against that.
      def make_distributed(*_)
        raise DistributedError, 'distributed objects not supported from this protocol (DeadProtocol)'
      end

      config_reader :debug, :load_limit
    end
  end
end