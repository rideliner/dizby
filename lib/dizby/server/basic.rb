# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/stream/query_ref'
require 'dizby/utility/self_pipe'
require 'dizby/utility/monitor'

module Dizby
  class BasicServer < AbstractServer
    def initialize(args, stream)
      super(args.config) { |msg| "#{args.uri} : #{msg}" }

      @uri = args.uri
      @front = args.front
      @stream = stream

      @exported_uri = Dizby.monitor([@uri])

      @shutdown_pipe = ShutdownPipe.new
    end

    def close
      log.debug('Closing local server')
      if stream
        stream.close
        self.stream = nil
      end

      shutdown_pipe.close
    end

    def shutdown
      log.debug('Shutting down local server')
      shutdown_pipe.shutdown
    end

    def accept
      shutdown_pipe.wait_or_raise(stream, LocalServerShutdown)
      log.debug('Accepting connection')
      stream.accept
    end

    def alive?
      return false unless stream
      return false if shutdown_pipe.shutdown?

      true
    end

    def to_obj(ref)
      case ref
      when nil
        front
      when QueryRef
        front[ref.to_s]
      else
        idconv.to_obj(ref)
      end
    end

    def to_id(obj)
      return nil if obj.__id__ == front.__id__
      idconv.to_id(obj)
    end

    attr_reader :uri
    config_reader :argc_limit

    def add_uri_alias(uri)
      log.debug("Adding uri alias: #{uri}")

      exported_uri.synchronize do
        exported_uri << uri unless exported_uri.include?(uri)
      end
    end

    def here?(uri)
      exported_uri.synchronize { exported_uri.include?(uri) }
    end

    private

    config_reader :idconv
    attr_reader :front, :exported_uri
    attr_accessor :stream, :shutdown_pipe
  end
end
