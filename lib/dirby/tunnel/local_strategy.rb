
require 'dirby/tunnel/tunnelable_local'

module Dirby
  class LocalTunnelStrategy
    include TunnelableLocal

    def initialize(server_port)
      @server_port = server_port
    end

    def write(ssh, stream)
      local_tunnel = create_local_tunnel(ssh, @server_port)

      stream.puts local_tunnel
    end

    def read(stream)
      local_tunnel = stream.gets.chomp.to_i

      [local_tunnel, nil]
    end
  end
end
