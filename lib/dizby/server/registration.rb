# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

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
