# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
      succ, result = Array.new(2) { read }
      [succ, result]
    end
  end
end
