
require 'dirby/basics/messenger'

module Dirby
  class BasicClient < Messenger
    def initialize(server, stream, remote_uri)
      super(server, stream)

      @remote_uri = remote_uri

      # write the other side's remote_uri to the socket
      @stream.write(dump_data(@remote_uri))
    end

    def send_request(ref, msg_id, *args, &block)
      arr = [ref, msg_id.id2name, args.length, *args, block]
      arr.map! { |ele| dump_data(ele) }
      @stream.write(arr.join(''))
    end

    def recv_reply
      succ, result = 2.times.map { load_data }
      [succ, result]
    end
  end
end
