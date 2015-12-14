
require 'dirby/tunnel/tunnelable_local'
require 'dirby/tunnel/tunnelable_remote'

module Dirby
  class BidirectionalTunnelStrategy
    include TunnelableLocal
    include TunnelableRemote

    def initialize(server_port, client_port)
      @server_port = server_port
      @client_port = client_port
    end

    def write(ssh, stream)
      local_tunnel = create_local_tunnel(ssh, @server_port)
      remote_tunnel = create_remote_tunnel(ssh, @client_port)

      stream.puts local_tunnel, remote_tunnel
    end

    def read(stream)
      local_tunnel = stream.gets.chomp.to_i
      remote_tunnel = stream.gets.chomp.to_i

      [local_tunnel, remote_tunnel]
    end
  end
end
