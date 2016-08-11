# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/basic'
require 'dizby/server/abstract'

module Dizby
  class DeadProtocol
    include BasicProtocol

    self.scheme = ''

    refine(:server, '') do |_, config|
      raise NonAcceptingServer, Server.new(config)
    end

    class Server < AbstractServer
      # A DeadProtocol server doesn't allow backwards connections
      # therefore, making a distributed object goes against that.
      def make_distributed(*_)
        raise DistributedError,
              'distributed objects not supported from DeadProtocol'
      end
    end
  end
end
