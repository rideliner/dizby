# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  module TunnelableLocal
    def create_local_tunnel(ssh, server_port)
      ssh.forward.local 0, 'localhost', server_port
    end
  end
end
