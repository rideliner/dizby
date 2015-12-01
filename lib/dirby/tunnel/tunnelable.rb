
module Dirby
  module TunnelableLocal
    def create_local_tunnel(ssh, server_port)
      ssh.forward.local 0, 'localhost', server_port
    end
  end

  module TunnelableRemote
    def create_remote_tunnel(ssh, client_port)
      remote_tunnel_port = nil
      ssh.forward.remote client_port, 'localhost', 0, 'localhost' do |remote_port|
        remote_tunnel_port = remote_port
        :no_exception
      end

      ssh.loop { remote_tunnel_port.nil? }
      raise Net::SSH::Exception, 'remote forwarding request failed' if remote_tunnel_port == :error
    end
  end
end
