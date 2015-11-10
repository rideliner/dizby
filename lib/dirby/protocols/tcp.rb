
require 'dirby/basics'
require 'dirby/delegate'

require 'socket'
require 'fcntl'

module Dirby
  class TCProtocol
    include BasicProtocol

    self.scheme = 'drb'

    self.regex = /^#{self.scheme}:\/\/(?<host>.*?)?(?::(?<port>\d+))?$/

    def self.open_server(front, config, host, port)
      port &&= port.to_i

      Server.new front, config, host, port
    end

    def self.open_client(server, host, port)
      port &&= port.to_i

      socket = TCPSocket.open(host, port)
      set_sockopt(socket)

      BasicClient.new(server, socket, "#{self.scheme}://#{host}:#{port}")
    end

    private

    def self.getservername
      Socket::gethostbyname(Socket::gethostname)[0] rescue 'localhost'
    end

    def self.set_sockopt(soc)
      soc.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      soc.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) if defined? Fcntl::FD_CLOEXEC
    end

    class Server < BasicServer
      include PolymorphicDelegated

      def initialize(front, config, host, port)
        port ||= 0

        if host.empty?
          host = TCProtocol.getservername
          socket = self.class.open_socket_inaddr_any(host, port)
        else
          socket = TCPServer.open(host, port)
        end

        port = socket.addr[1] if port == 0

        super("drb://#{host}:#{port}", front, socket, config)

        TCProtocol.set_sockopt(socket)

        @port = port
      end

      attr_reader :port

      def accept
        s = nil
        loop do
          s = super
          break if !tcp_acl || tcp_acl.allow_socket?(s) # TODO not tested
          s.close
        end

        TCProtocol.set_sockopt(s)
        BasicConnection.new(self, s)
      end

      private

      config_reader :tcp_acl

      def self.open_socket_inaddr_any(host, port)
        infos = Socket::getaddrinfo(host, nil, Socket::AF_UNSPEC,
                                    Socket::SOCK_STREAM, 0, Socket::AI_PASSIVE)
        families = Hash[*infos.collect { |af, *_| af }.uniq.zip([]).flatten]
        return TCPServer.open('0.0.0.0', port) if families.has_key?('AF_INET')
        return TCPServer.open('::', port) if families.has_key?('AF_INET6')
        return TCPServer.open(port)
      end
    end
  end
end