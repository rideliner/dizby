# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/stream/messenger'
require 'dizby/utility/self_pipe'

module Dizby
  class BasicConnection < Messenger
    def initialize(server, stream)
      super(server, stream)

      # get the uri that the client recognizes the server as
      @remote_uri = read

      @shutdown_pipe = SelfPipe.new(*IO.pipe)
      @object_space = []
    end

    def recv_request
      wait_for_stream

      ref, msg, argc = Array.new(3) { read }

      @server.log.debug("called through proxy: #{ref} #{msg}")
      raise ConnectionError, 'too many arguments' if @server.argc_limit < argc

      argv = Array.new(argc) { read }
      block = read

      ro = @server.to_obj(ref)
      [ro, msg, argv, block]
    end

    def send_reply(succ, result)
      write(dump_data(succ) + dump_data(result, !succ))
    rescue
      raise ConnectionError, $!.message, $!.backtrace
    end

    def close
      @object_space.clear
      shutdown_pipe.close_write if shutdown_pipe
      super
    end

    private

    # when a distributed object is made through a connection, store it
    # so that it doesn't get consumed by the garbage collector
    def make_distributed(_obj, _error)
      distributed = super
      @object_space << distributed
      distributed
    end

    def wait_for_stream
      readable, = IO.select([@stream, shutdown_pipe.read])
      raise RemoteServerShutdown if readable.include?(shutdown_pipe.read)
    rescue IOError
      raise RemoteServerShutdown
    end

    attr_reader :shutdown_pipe
  end
end
