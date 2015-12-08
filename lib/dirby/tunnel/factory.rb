
require 'dirby/tunnel/strategy'
require 'dirby/utility/semibuilt'

module Dirby
  class TunnelFactory
    def initialize(server, port)
      @server = server
      @port = port
    end

    def create(type)
      SemibuiltObject.new(type, @server, strategy)
    end

    def bidirectional?
      @server.respond_to?(:port)
    end

    def strategy
      if bidirectional?
        BidirectionalTunnelStrategy.new(@port, @server.port)
      else
        LocalTunnelStrategy.new(@port)
      end
    end
  end
end
