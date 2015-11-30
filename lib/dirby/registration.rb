
module Dirby
  @servers = []

  def self.register_server(server)
    Rubinius.synchronize(@servers) { @servers << server }
  end

  def self.unregister_server(server)
    Rubinius.synchronize(@servers) { @servers.delete(server) }
  end

  # returns [success, object]
  def self.get_obj(uri, ref)
    Rubinius.synchronize(@servers) do
      local_server = @servers.find { |s| s && s.here?(uri) }

      [!local_server.nil?, local_server && local_server.to_obj(ref)]
    end
  end
end
