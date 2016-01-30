# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/tunnel/tunnelable_local'
require 'dizby/tunnel/tunnelable_remote'

module Dizby
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
