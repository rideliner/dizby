
require 'dirby/basics'
require 'dirby/basics/tunnel'
require 'dirby/tunnel/strategy'

require 'socket'

module Dirby
  class SecureProtocol
    include BasicProtocol

    self.scheme = 'drbsec'

    refine(:spawn,
           %r{^#{scheme}://#{Regex::USER}?#{Regex::HOST}#{Regex::PORT}?#{Regex::QUERY}?$}
          ) do |server, command, (user, host, port, query)|
      tunnel, local_port, remote_port = get_spawn_tunnel(server, command, user, host, port)

      socket = TCPSocket.open('localhost', local_port)
      TCProtocol.apply_sockopt(socket)

      client = BasicClient.new(tunnel, socket, "#{scheme}://#{host}:#{remote_port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    refine(:client,
           %r{^#{scheme}://#{Regex::USER}?#{Regex::HOST}#{Regex::PORT}#{Regex::QUERY}?$}
          ) do |server, (user, host, port, query)|
      port &&= port.to_i

      tunnel, local_port = get_basic_tunnel(server, user, host, port)

      socket = TCPSocket.open('localhost', local_port)
      TCProtocol.apply_sockopt(socket)

      # set tunnel as the server so that the custom uri can be passed to the remote
      client = BasicClient.new(tunnel, socket, "#{scheme}://#{host}:#{port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    class << self
      private

      # returns the tunnel and the local port it is running on
      def get_basic_tunnel(server, user, host, port)
        strategy, klass = get_tunnel_strategy(server, port)

        tunnel = BasicTunnel.new(server, strategy, user, host)

        [klass.new(server, tunnel), tunnel.local_port]
      end

      def get_spawn_tunnel(server, command, user, host, port)
        strategy, klass = get_tunnel_strategy(server, port)

        tunnel = BasicSpawnTunnel.new(server, strategy, command, user, host)

        [klass.new(server, tunnel), tunnel.local_port, tunnel.remote_port]
      end

      # returns the tunnel strategy (Local/Bidirectional) and
      # the class that should be instantiated for the given type
      def get_tunnel_strategy(server, port)
        if server.respond_to?(:port)
          [BidirectionalTunnelStrategy.new(port, server.port), ResponseTunnel]
        else
          [LocalTunnelStrategy.new(port), Tunnel]
        end
      end
    end

    class Tunnel < Delegator
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

    class ResponseTunnel < Tunnel
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
