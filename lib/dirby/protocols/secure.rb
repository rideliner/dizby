
require 'dirby/basics'
require 'dirby/basics/tunnel'
require 'dirby/tunnel/factory'

require 'socket'

module Dirby
  class SecureProtocol
    include BasicProtocol

    self.scheme = 'drbsec'

    refine(:spawn,
           %r{^#{scheme}://#{Regex::USER}?#{Regex::HOST}#{Regex::PORT}?#{Regex::QUERY}?$}
          ) do |server, command, (user, host, port, query)|
      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicSpawnTunnel).with(command, user, host)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      delegate = delegatable_tunnel(factory, server, tunnel)
      client = BasicClient.new(delegate, socket, "#{scheme}://#{host}:#{tunnel.remote_port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    refine(:client,
           %r{^#{scheme}://#{Regex::USER}?#{Regex::HOST}#{Regex::PORT}#{Regex::QUERY}?$}
          ) do |server, (user, host, port, query)|
      port &&= port.to_i

      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicTunnel).with(user, host)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      delegate = delegatable_tunnel(factory, server, tunnel)
      # set tunnel as the server so that the custom uri can be passed to the remote
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
