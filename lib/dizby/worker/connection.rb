# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/worker/invoke_method'

module Dizby
  class ConnectionWorker
    def initialize(server, conn)
      @server = server
      @conn = conn

      @thread = Thread.start { process_requests }
    end

    def close
      @conn.close unless @conn.closed?

      # TODO: @thread gets set to nil for some reason...
      @thread.join if @thread
    end

    private

    def process_requests
      loop { break unless process_request }
    rescue RemoteServerShutdown
      @server.log.debug("lost connection to server at #{@conn.remote_uri}")
    ensure
      @conn.close unless @conn.closed?
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
