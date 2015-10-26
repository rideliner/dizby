
require 'drb/error'
require 'drb/basics/messenger'

module DRb
  class BasicConnection < Messenger
    def initialize(server, stream)
      super(server, stream)

      # get the uri that the client recognizes the server as
      @remote_uri = load_data(@server.load_limit)
    end

    def recv_request
      limit = @server.load_limit

      ref = load_data(limit)
      msg = load_data(limit)
      argc = load_data(limit)

      @server.log "called through proxy: #{ref} #{msg}"
      raise ConnectionError, 'too many arguments' if @server.argc_limit < argc

      argv = Array.new(argc) { |_| load_data(limit) }
      block = load_data(limit)

      ro = @server.to_obj(ref)
      [ ro, msg, argv, block ]
    end

    def send_reply(succ, result)
      stream.write(dump_data(succ) + dump_data(result, !succ))
    rescue
      raise ConnectionError, $!.message, $!.backtrace
    end
  end
end