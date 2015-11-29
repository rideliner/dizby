
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
end
