# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'net/ssh'

module Dizby
  class AbstractTunnel
    def initialize(server, strategy, user, host, **options)
      @server = server
      ssh_config = options[:ssh] || @server.config[:ssh] || {}
      @config = [host, user, ssh_config]
      @strategy = strategy

      open_ssh_tunnel
    end

    # wait(ssh) is not defined in this class
    def loop_ssh(ssh, output)
      get_and_write_ports(ssh, output)
      wait(ssh)
    ensure
      output.close
      ssh.close if ssh
    end

    def read_ports(input)
      @local_port, @remote_port = @strategy.read(input)
    end

    def get_and_write_ports(ssh, output)
      @strategy.write(ssh, output)
    end

    def open_ssh_tunnel
      reader, writer = IO.pipe

      @thread =
        Thread.start(Net::SSH.start(*@config)) do |ssh|
          loop_ssh(ssh, writer)
        end

      read_ports(reader)
    rescue
      @thread.abort_on_exception = true
      close
    ensure
      reader.close
    end

    def close
      @thread.join if @thread && @thread.alive?
    end

    attr_reader :local_port, :remote_port
  end
end
