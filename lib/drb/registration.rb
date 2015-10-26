
module DRb
  @servers = Array.new

  def self.register_server(server)
    @servers << server
  end

  def self.unregister_server(server)
    @servers.delete(server)
  end
end