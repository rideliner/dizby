# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/manager'
require 'dizby/converter/simple'
require 'dizby/worker/service'
require 'dizby/utility/log'
require 'dizby/server/non_accepting'

module Dizby
  class Service
    def initialize(uri: '', front: nil, **config)
      config = DEFAULT_CONFIG.merge(config)

      args = ServerArguments.new(uri, front, config)
      self.server = ProtocolManager.open_server(args)
      init_worker

      Dizby.register_server(@server)
    end

    def self.open(*args, **kwargs)
      service = new(*args, **kwargs)

      yield service if block_given?
    ensure
      service.close
      service.wait
    end

    def self.start(*args, **kwargs)
      service = new(*args, **kwargs)

      yield service if block_given?
    ensure
      service.wait
    end

    def connect_to(uri:, **options, &block)
      args = ClientArguments.new(uri, options)
      proxy = ObjectProxy.new(*@server.connect_to(args))
      block ? call_connect_block(proxy, &block) : proxy
    end

    def spawn_on(uri:, command:, **options, &block)
      args = SpawnArguments.new(uri, command, options)
      proxy = ObjectProxy.new(*@server.spawn_on(args))
      block ? call_spawn_block(proxy, &block) : proxy
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

    def init_worker
      if @server.is_a?(NonAcceptingServer)
        # This is to allow servers that don't accept connections
        # Not all servers will allow connections back to them, so don't create
        # a ServiceWorker that is going to be accepting connections.
        @server.log.warn('using a server that does not allow connections')
      else
        @worker = ServiceWorker.new(@server)
      end
    end

    def call_connect_block(proxy)
      yield proxy
    ensure
      proxy.__dizby_close__
    end

    def call_spawn_block(proxy)
      yield proxy
    ensure
      proxy.__dizby_exit__
    end
  end
end
