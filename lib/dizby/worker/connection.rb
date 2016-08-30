# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/worker/invoke_method'

module Dizby
  class ConnectionWorker
    def initialize(service_worker, server, conn)
      @parent = service_worker
      @server = server
      @conn = conn

      @thread = Thread.start { process_requests }
    end

    def shutdown
      @parent = nil

      @server.log.debug('Shutting down connection to client')
      @conn.shutdown

      @thread.join if @thread && @thread.alive?
    end

    def close
      @conn.close

      return unless @parent

      @parent.remove_worker(self)
      @parent = nil
    end

    private

    def process_requests
      loop { break unless process_request }
    rescue RemoteServerShutdown
      @server.log.debug('Lost connection to client')
    rescue
      @server.log.backtrace($!)
    ensure
      close
    end

    def process_request
      succ, result = InvokeMethod.new(@server, *@conn.recv_request).perform

      @server.log.backtrace(result) unless succ

      begin
        @conn.send_reply(succ, result)
      rescue
        @server.log.backtrace($!)
      end

      succ
    end
  end
end
