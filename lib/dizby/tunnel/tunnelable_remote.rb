# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
        raise Net::SSH::Exception, 'remote forwarding request failed'
      end

      remote_tunnel_port
    end
  end
end
