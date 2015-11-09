
require 'drb/basics'
require 'drb/error'
require 'drb/util'

module DRb
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
        raise Exception, '' # TODO meaningful error
      end

      config_reader :debug, :load_limit
    end
  end
end