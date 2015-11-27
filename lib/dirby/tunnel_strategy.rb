
module Dirby
  module TunnelableLocal
    def create_local_tunnel(ssh, server_port)
      ssh.forward.local 0, 'localhost', server_port
    end
  end

  module TunnelableRemote
    def create_remote_tunnel(ssh, client_port)
      ssh.forward.remote client_port, 'localhost', 0, 'localhost'
      remote_ports = ssh.forward.instance_variable_get :@remote_forwarded_ports

      remote_tunnel_port = nil

      ssh.loop {
        remote_tunnel_port = remote_ports.select { |_, v| v.port == client_port }
        remote_tunnel_port.empty?
      }

      remote_tunnel_port.keys.first.first
    end
  end

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

      [ local_tunnel, nil ]
    end
  end

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

      [ local_tunnel, remote_tunnel ]
    end
  end
end
