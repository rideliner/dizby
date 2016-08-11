# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/tunnel/tunnelable_local'

module Dizby
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
