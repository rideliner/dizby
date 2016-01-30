# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/server/registration'
require 'dizby/distributed/proxy'

module Dizby
  class SemiObjectProxy
    def initialize(uri, ref)
      @uri = uri
      @ref = ref
    end

    def evaluate(server)
      # cut down on network times by using the object if it exists locally
      success, obj = Dizby.get_obj(@uri, @ref)

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
