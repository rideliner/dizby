# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/worker/connection'

module Dizby
  class ServiceWorker
    def initialize(server)
      @server = server
      @thread = Thread.start { run }
      @workers = Dizby.monitor([])
    end

    def join
      @thread.join if @thread
    end

    def remove_worker(worker)
      workers.synchronize { workers.delete(worker) }
    end

    private

    attr_accessor :workers

    def run
      loop do
        worker = accept_connection
        workers.synchronize { workers << worker if worker }
      end
    rescue LocalServerShutdown
      @server.log.debug('Server shutdown')
    ensure
      workers.synchronize { workers.each(&:shutdown) }

      @server.close
    end

    def accept_connection
      connection = @server.accept
      return nil unless connection

      @server.add_uri_alias connection.remote_uri
      ConnectionWorker.new(self, @server, connection)
    end
  end
end
