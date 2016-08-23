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
    end

    def join
      @thread.join if @thread
    end

    private

    def run
      workers = []
      loop do
        worker = accept_connection
        workers << worker if worker
      end
    rescue LocalServerShutdown
      @server.log.debug('Server shutdown')
    ensure
      @server.close if @server.alive?

      workers.each(&:close)
    end

    def accept_connection
      connection = @server.accept
      return nil unless connection

      @server.add_uri_alias connection.remote_uri
      ConnectionWorker.new(@server, connection)
    end
  end
end
