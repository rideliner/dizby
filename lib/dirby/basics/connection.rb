
require 'dirby/basics/messenger'
require 'dirby/utility/pipe'

module Dirby
  class BasicConnection < Messenger
    def initialize(server, stream)
      super(server, stream)

      # get the uri that the client recognizes the server as
      @remote_uri = load_data(@server.load_limit)

      @shutdown_pipe = SelfPipe.new(*IO.pipe)
    end

    def recv_request
      begin
        readable, = IO.select([stream, shutdown_pipe.read])
        raise ServerShutdown if readable.include?(shutdown_pipe.read)
      rescue IOError
        raise ServerShutdown
      end

      limit = @server.load_limit

      ref = load_data(limit)
      msg = load_data(limit)
      argc = load_data(limit)

      @server.log.debug("called through proxy: #{ref} #{msg}")
      raise ConnectionError, 'too many arguments' if @server.argc_limit < argc

      argv = Array.new(argc) { load_data(limit) }
      block = load_data(limit)

      ro = @server.to_obj(ref)
      [ro, msg, argv, block]
    end

    def send_reply(succ, result)
      stream.write(dump_data(succ) + dump_data(result, !succ))
    rescue
      raise ConnectionError, $!.message, $!.backtrace
    end

    def close
      shutdown_pipe.close_write unless shutdown_pipe.nil?
      super
    end

    attr_reader :shutdown_pipe
  end
end
