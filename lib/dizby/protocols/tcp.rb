# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/basic'
require 'dizby/stream/client'
require 'dizby/stream/connection'
require 'dizby/server/basic'

require 'socket'

module Dizby
  class TCProtocol
    include BasicProtocol

    self.scheme = 'drb'

    refine(
      :server,
      "#{scheme}://%{host}?%{port}?"
    ) do |front, config, (host, port)|
      port &&= port.to_i

      Server.new front, config, host, port
    end

    refine(
      :client,
      "#{scheme}://%{host}?%{port}?%{query}?"
    ) do |server, (host, port, query)|
      port &&= port.to_i

      socket = TCPSocket.open(host, port)
      apply_sockopt(socket)

      client = BasicClient.new(server, socket, "#{scheme}://#{host}:#{port}")
      query &&= QueryRef.new(query)

      [client, query]
    end

    class << self
      def getservername
        Socket.gethostbyname(Socket.gethostname)[0]
      rescue
        'localhost'
      end

      def apply_sockopt(soc)
        soc.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      end
    end

    class Server < BasicServer
      def initialize(front, config, host, port)
        port ||= 0

        if host.empty?
          host = TCProtocol.getservername
          socket = self.class.open_socket_inaddr_any(host, port)
        else
          socket = TCPServer.open(host, port)
        end

        port = socket.addr[1] if port.zero?

        super("drb://#{host}:#{port}", front, socket, config)

        TCProtocol.apply_sockopt(socket)

        @port = port
      end

      attr_reader :port

      def accept
        socket = nil
        loop do
          socket = super
          break if !tcp_acl || tcp_acl.allow_socket?(socket) # TODO: not tested
          socket.close
        end

        TCProtocol.apply_sockopt(socket)
        BasicConnection.new(self, socket)
      end

      config_reader :tcp_acl
      private :tcp_acl

      def self.open_socket_inaddr_any(host, port)
        infos = Socket.getaddrinfo(
          host, nil, Socket::AF_UNSPEC,
          Socket::SOCK_STREAM, 0, Socket::AI_PASSIVE
        )

        families = Hash[*infos.map { |af, *_| af }.uniq.zip([]).flatten]
        return TCPServer.open('0.0.0.0', port) if families.key?('AF_INET')
        return TCPServer.open('::', port) if families.key?('AF_INET6')
        TCPServer.open(port)
      end
    end
  end
end
