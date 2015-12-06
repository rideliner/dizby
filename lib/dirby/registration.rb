
require 'dirby/utility/monitor'

module Dirby
  @servers = Dirby.monitor([])

  def self.register_server(server)
    @servers.synchronize { @servers << server }
  end

  def self.unregister_server(server)
    @servers.synchronize { @servers.delete(server) }
  end

  # returns [success, object]
  def self.get_obj(uri, ref)
    @servers.synchronize do
      local_server = @servers.find { |s| s && s.here?(uri) }

      [!local_server.nil?, local_server && local_server.to_obj(ref)]
    end
  end
end
