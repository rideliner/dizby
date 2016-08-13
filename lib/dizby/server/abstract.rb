# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/manager'
require 'dizby/distributed/object'
require 'dizby/utility/configurable'
require 'dizby/utility/log'

require 'poly_delegate'

module Dizby
  class AbstractServer
    include PolyDelegate::Delegated
    extend Configurable

    def initialize(config, &log_transform)
      @config = config
      @log = Dizby::Logger.new(config[:log] || {}, &log_transform)
    end

    attr_reader :log
    config_reader :load_limit

    def connect_to(uri)
      ProtocolManager.open_client(self, uri)
    end

    def spawn_on(command, uri)
      ProtocolManager.spawn_server(self, command, uri)
    end

    def shutdown; end

    def alive?
      true
    end

    def make_distributed(obj, error)
      if error
        RemoteDistributedError.new(obj)
      else
        log.debug("making distributed: #{obj.inspect}")
        DistributedObject.new(obj, self)
      end
    end
  end
end
