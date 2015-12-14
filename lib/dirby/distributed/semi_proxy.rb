
require 'dirby/server/registration'
require 'dirby/distributed/proxy'

module Dirby
  class SemiObjectProxy
    def initialize(uri, ref)
      @uri = uri
      @ref = ref
    end

    def evaluate(server)
      # cut down on network times by using the object if it exists locally
      success, obj = Dirby.get_obj(@uri, @ref)

      if success
        server.log.debug("found local obj: #{obj.inspect}")
        obj
      else
        server.log.debug("creating proxy to #{@ref} on #{@uri}")
        client, = server.connect_to(@uri) # throw away the ref
        ObjectProxy.new(client, @ref)
      end
    end
  end
end
