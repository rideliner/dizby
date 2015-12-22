
require 'dizby/stream/messenger'

module Dizby
  class BasicClient < Messenger
    def initialize(server, stream, remote_uri)
      super(server, stream)

      @remote_uri = remote_uri

      # write the other side's remote_uri to the socket
      write(dump_data(@remote_uri))
    end

    def send_request(ref, msg_id, *args, &block)
      arr = [ref, msg_id.id2name, args.length, *args, block]
      arr.map! { |ele| dump_data(ele) }
      write(arr.join(''))
    end

    def recv_reply
      succ, result = 2.times.map { read }
      [succ, result]
    end
  end
end
