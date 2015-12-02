
require 'dirby/basics'
require 'dirby/error'
require 'dirby/utility/log'
require 'dirby/utility/config'

module Dirby
  class DeadProtocol
    include BasicProtocol

    self.scheme = ''

    refine(:server, /^$/) do |_, config|
      raise NonAcceptingServer, Server.new(config)
    end

    class Server < AbstractServer
      # A DeadProtocol server doesn't allow backwards connections
      # therefore, making a distributed object goes against that.
      def make_distributed(*_)
        raise DistributedError, 'distributed objects not supported from this protocol (DeadProtocol)'
      end
    end
  end
end
