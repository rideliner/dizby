
require 'dirby/util'

module Dirby
  @servers = [ ]

  def self.register_server(server)
    Rubinius.synchronize(@servers) {
      @servers << server
    }
  end

  def self.unregister_server(server)
    Rubinius.synchronize(@servers) {
      @servers.delete(server)
    }
  end

  # returns [success, object]
  def self.get_obj(uri, ref) # TODO test this
    Rubinius.synchronize(@servers) {
      local_server = @servers.find { |s| !s.nil? && s.here?(uri) }
      empty = local_server.nil?

      [ !empty, empty ? nil : local_server.to_obj(ref) ]
    }
  end
end
