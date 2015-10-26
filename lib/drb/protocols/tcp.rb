
require 'drb/basics'
require 'socket'

module DRb
  class TCProtocol
    include BasicProtocol

    self.scheme = 'drb'

    self.regex = /^#{self.scheme}:\/\/(?<host>.*?)?(?::(?<port>\d+))?$/

    def self.open_server(front, config, host, port)
      Server.new front, config, host, port.to_i
    end

    def self.open_client(server, host, port)
      Client.new server, host, port.to_i
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
      def initialize(front, config, host, port)
        port ||= 0

        if host.empty?
          host = TCProtocol.getservername
          soc = self.class.open_server_inaddr_any(host, port)
        else
          soc = TCPServer.open(host, port)
        end

        port = soc.addr[1] if port == 0

        super("drb://#{host}:#{port}", front, config)

        @stream = soc
        TCProtocol.set_sockopt(@stream)
      end

      def close
        @stream.close
      end

      def accept
        s = nil
        loop do
          s = @stream.accept
          break if (@acl ? @acl.allow_socket?(s) : true)
          s.close
        end

        Connection.new(self, s)
      end

      private

      def self.open_server_inaddr_any(host, port)
        infos = Socket::getaddrinfo(host, nil, Socket::AF_UNSPEC,
                                    Socket::SOCK_STREAM, 0, Socket::AI_PASSIVE)
        families = Hash[*infos.collect { |af, *_| af }.uniq.zip([]).flatten]
        return TCPServer.open('0.0.0.0', port) if families.has_key?('AF_INET')
        return TCPServer.open('::', port) if families.has_key?('AF_INET6')
        return TCPServer.open(port)
      end
    end

    class Client < BasicClient
      def initialize(server, host, port)
        socket = TCPSocket.open(host, port)
        TCProtocol.set_sockopt(socket)

        super(server, socket, "drb://#{host}:#{port}")
      end
    end

    class Connection < BasicConnection
      def initialize(server, socket)
        TCProtocol.set_sockopt(socket)

        super(server, socket)
      end
    end
  end

  ProtocolMgr.add_protocol TCProtocol
end