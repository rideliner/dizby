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
require 'dizby/tunnel/factory'

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

      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicSpawnTunnel).with(user, host, args)

      socket = TCPSocket.open('localhost', tunnel.local_port)
      TCProtocol.apply_sockopt(socket)

      delegate = delegatable_tunnel(factory, server, tunnel)
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

      factory = TunnelFactory.new(server, port)
      tunnel = factory.create(BasicTunnel).with(user, host, args)

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
