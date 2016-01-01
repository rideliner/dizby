# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  module TunnelableLocal
    def create_local_tunnel(ssh, server_port)
      ssh.forward.local 0, 'localhost', server_port
    end
  end
end
