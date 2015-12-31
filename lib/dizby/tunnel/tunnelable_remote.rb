
module Dizby
  module TunnelableRemote
    def create_remote_tunnel(ssh, client_port)
      remote_tunnel_port = nil
      ssh.forward.remote client_port, 'localhost',
                         0, 'localhost' do |remote_port|
        remote_tunnel_port = remote_port
        :no_exception
      end

      ssh.loop { remote_tunnel_port.nil? }

      if remote_tunnel_port == :error
        fail Net::SSH::Exception, 'remote forwarding request failed'
      end

      remote_tunnel_port
    end
  end
end