
require 'dirby/basics'
require 'dirby/tunnel'

require 'socket'

module Dirby
  class SecureProtocol
    include BasicProtocol

    self.scheme = 'drbsec'

    # [ user, host, port ]
    # -host- defaults to '', the rest default to nil
    self.regex = /^#{self.scheme}:\/\/(?:(?<user>.+)@)?(?<host>.*?)?(?::(?<port>\d+))?$/

    def self.spawn_server(command, config, user, host, port)

    end

    def self.open_client(server, user, host, port)
      port &&= port.to_i

      if server.respond_to?(:port)
        original_port = server.port
      else
        raise Exception, '' # TODO meaningful exception
      end

      tunnel = Tunnel.new(server, user, host, port, original_port)
      local_port = tunnel.__undelegated_get__(:@local_port)

      socket = TCPSocket.open('localhost', local_port)
      TCProtocol.set_sockopt(socket)

      # set tunnel as the server so that the custom uri can be passed to the remote
      BasicClient.new(tunnel, socket, "#{self.scheme}://#{host}:#{port}")
    end

    private

    class Tunnel < Delegator
      def initialize(server, user, host, port, original_port)
        super(server)

        @tunnel = BasicTunnel.new(user, host, port, original_port, config[:ssh_config])
        @remote_port = @tunnel.instance_variable_get(:@remote_port)
        @local_port = @tunnel.instance_variable_get(:@local_port)
      end

      def uri # overload the uri of the server
        # we use the drb protocol for the rebound connection
        "drb://localhost:#{@remote_port}"
      end

      def close # TODO test this
        @tunnel.close # specifically, test this...
        super
        @tunnel.thread.join
      end
    end
  end
end