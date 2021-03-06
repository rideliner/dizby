# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  class DistributedError < RuntimeError; end
  class ConnectionError < DistributedError; end
  class ServerNotFound < DistributedError; end
  class BadURI < DistributedError; end
  class BadScheme < DistributedError; end
  class LocalServerShutdown < DistributedError; end
  class RemoteServerShutdown < ConnectionError; end
  class SpawnError < DistributedError; end

  class RemoteDistributedError < DistributedError
    def initialize(error)
      @reason = error.class.to_s
      super("#{error.message} (#{@reason})")
      set_backtrace(error.backtrace)
    end

    attr_reader :reason
  end
end
