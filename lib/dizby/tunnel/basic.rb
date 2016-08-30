# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/tunnel/abstract'

module Dizby
  class BasicTunnel < AbstractTunnel
    def initialize(*abstract_args, client_args)
      @working = true

      super(*abstract_args, **client_args.options)
    end

    def wait(ssh)
      ssh.loop { @working }
    end

    def close
      @working = false
      super
    end
  end
end
