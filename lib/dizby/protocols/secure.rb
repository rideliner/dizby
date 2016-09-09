# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/basic'
require 'dizby/stream/client'
require 'dizby/stream/connection'
require 'dizby/server/basic'
require 'dizby/tunnel/basic'
require 'dizby/tunnel/basic_spawn'
require 'dizby/tunnel/local_strategy'
require 'dizby/tunnel/bidirectional_strategy'

require 'socket'

module Dizby
  class SecureProtocol
    include BasicProtocol

    self.scheme = 'drbsec'

    refine(
      :spawn,
      "#{scheme}://%{user}?%{host}%{port}?%{query}?"
    ) do |args, server, (user, host, port, query)|
      port = port.to_i

      delegate = create_delegated_tunnel(
        BasicSpawnTunnel, server, port, user, host, args
      )

      tunnel = delegate.__undelegated_get__(:@tunnel)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      client = BasicClient.new(
        delegate, socket, "#{scheme}://#{host}:#{tunnel.remote_port}"
      )

      query &&= QueryRef.new(query)

      [client, query]
    end

    refine(
      :client,
      "#{scheme}://%{user}?%{host}%{port}%{query}?"
    ) do |args, server, (user, host, port, query)|
      port = port.to_i

      delegate = create_delegated_tunnel(
        BasicTunnel, server, port, user, host, args
      )

      tunnel = delegate.__undelegated_get__(:@tunnel)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      client = BasicClient.new(delegate, socket, "#{scheme}://#{host}:#{port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    def self.create_delegated_tunnel(tunnel_type, server, port, *args)
      strategy, delegated_type =
        if server.respond_to?(:port)
          [BidirectionalTunnelStrategy.new(port, server.port), ResponseTunnel]
        else
          [LocalTunnelStrategy.new(port), DirectTunnel]
        end

      tunnel = tunnel_type.new(server, strategy, *args)
      delegated_type.new(server, tunnel)
    end

    class DirectTunnel < PolyDelegate::Delegator
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
      def uri # overload the uri of the server
        # we use the drb protocol for the rebound connection
        "drb://localhost:#{@tunnel.remote_port}"
      end
    end
  end
end
