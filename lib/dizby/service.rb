# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/manager'
require 'dizby/converter/simple'
require 'dizby/worker/service'
require 'dizby/utility/log'

module Dizby
  class Service
    def initialize(uri: '', front: nil, **config)
      config = DEFAULT_CONFIG.merge(config)

      args = ServerArguments.new(uri, front, config)
      self.server = ProtocolManager.open_server(args)
    rescue NonAcceptingServer => err
      # This is to allow servers that don't accept connections
      # Not all servers will allow connections back to them, so don't allow it
      self.server = err.server
      @server.log.warn('using a server that does not allow connections')
    else
      @worker = ServiceWorker.new(@server)
    ensure
      Dizby.register_server(@server)
    end

    def connect_to(uri:, **options)
      args = ClientArguments.new(uri, options)
      ObjectProxy.new(*@server.connect_to(args))
    end

    def spawn_on(uri:, command:, **options)
      args = SpawnArguments.new(uri, command, options)
      ObjectProxy.new(*@server.spawn_on(args))
    end

    def close
      Dizby.unregister_server @server
      return unless alive?
      @server.shutdown
    end

    def alive?
      @server.alive?
    end

    def wait
      @worker.join if @worker
    end

    DEFAULT_CONFIG = {
      idconv: IdConverter,
      argc_limit: 256,
      load_limit: 256 * 1024 * 100,
      tcp_acl: nil
    }.freeze

    private

    def server=(srvr)
      raise DistributedError, 'server could not be opened' unless srvr
      @server = srvr
    end
  end
end
