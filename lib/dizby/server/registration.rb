# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/monitor'

module Dizby
  @servers = Dizby.monitor([])

  def self.register_server(server)
    @servers.synchronize { @servers << server }
  end

  def self.unregister_server(server)
    @servers.synchronize { @servers.delete(server) }
  end

  # returns [success, object]
  def self.get_obj(uri, ref)
    @servers.synchronize do
      local_server = @servers.find { |server| server && server.here?(uri) }

      [!local_server.nil?, local_server && local_server.to_obj(ref)]
    end
  end
end
