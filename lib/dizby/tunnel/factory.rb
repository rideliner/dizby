# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/tunnel/local_strategy'
require 'dizby/tunnel/bidirectional_strategy'
require 'dizby/utility/semi_built'

module Dizby
  class TunnelFactory
    def initialize(server, port)
      @server = server
      @port = port
    end

    def create(type)
      SemibuiltObject.new(type, @server, strategy)
    end

    def bidirectional?
      @server.respond_to?(:port)
    end

    def strategy
      if bidirectional?
        BidirectionalTunnelStrategy.new(@port, @server.port)
      else
        LocalTunnelStrategy.new(@port)
      end
    end
  end
end
