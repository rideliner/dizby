# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'net/ssh'

module Dizby
  class AbstractTunnel
    def initialize(server, strategy, user, host)
      @server = server
      @config = [user, host, @server.config[:ssh_config]]
      @strategy = strategy

      reader, writer = IO.pipe

      @thread =
        Thread.start do
          open_ssh(writer)
          writer.close
        end

      @thread.abort_on_exception = true

      read_ports(reader)
      reader.close
    end

    # wait(ssh) is not defined in this class
    def open_ssh(output)
      ssh = nil
      begin
        ssh = Net::SSH.start(*@config)

        get_and_write_ports(ssh, output)

        wait(ssh)
      ensure
        ssh.close if ssh
      end
    end

    def read_ports(input)
      @local_port, @remote_port = @strategy.read(input)
    end

    def get_and_write_ports(ssh, output)
      @strategy.write(ssh, output)
    end

    def close
      @thread.join
    end

    attr_reader :local_port, :remote_port
  end
end
