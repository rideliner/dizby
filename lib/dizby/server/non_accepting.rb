# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/server/abstract'

module Dizby
  class NonAcceptingServer < AbstractServer
    def make_distributed(*_)
      raise DistributedError,
            'distributed objects not supported from NonAcceptingServer'
    end
  end
end
