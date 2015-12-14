
require 'dirby/stream/readable'
require 'dirby/stream/writable'

module Dirby
  class Messenger
    include ReadableStream
    include WritableStream

    def initialize(server, stream)
      @server = server

      # stream needs to have the read(int), write(str), and close() methods
      # this value can be overloaded in the client/server classes for a protocol
      @stream = stream
    end

    attr_reader :server, :remote_uri

    def close
      @stream.close
    end

    def closed?
      !@stream || @stream.closed?
    end
  end
end
