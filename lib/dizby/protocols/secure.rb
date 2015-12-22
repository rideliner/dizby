
require 'dizby/protocol/basic'
require 'dizby/stream/client'
require 'dizby/stream/connection'
require 'dizby/server/basic'
require 'dizby/tunnel/basic'
require 'dizby/tunnel/factory'

require 'socket'

module Dizby
  class SecureProtocol
    include BasicProtocol

    self.scheme = 'drbsec'

    refine(:spawn,
           "#{scheme}://%{user}?%{host}%{port}?%{query}?"
          ) do |server, command, (user, host, port, query)|
      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicSpawnTunnel).with(command, user, host)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      delegate = delegatable_tunnel(factory, server, tunnel)
      client = BasicClient.new(delegate, socket,
                               "#{scheme}://#{host}:#{tunnel.remote_port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    refine(:client,
           "#{scheme}://%{user}?%{host}%{port}%{query}?"
          ) do |server, (user, host, port, query)|
      port &&= port.to_i

      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicTunnel).with(user, host)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      delegate = delegatable_tunnel(factory, server, tunnel)
      client = BasicClient.new(delegate, socket, "#{scheme}://#{host}:#{port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    def self.delegatable_tunnel(factory, server, tunnel)
      if factory.bidirectional?
        ResponseTunnel.new(server, tunnel)
      else
        DirectTunnel.new(server, tunnel)
      end
    end

    class DirectTunnel < Delegator
      def initialize(server, tunnel)
        super(server)

        @tunnel = tunnel
      end

      def close
        @tunnel.close
        super
        @tunnel.thread.join
      end
    end

    class ResponseTunnel < DirectTunnel
      def initialize(server, tunnel)
        super(server, tunnel)

        @remote_port = tunnel.remote_port
      end

      def uri # overload the uri of the server
        # we use the drb protocol for the rebound connection
        "drb://localhost:#{@remote_port}"
      end
    end
  end
end
