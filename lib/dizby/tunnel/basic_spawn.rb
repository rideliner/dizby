# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/tunnel/abstract'
require 'dizby/error'

module Dizby
  class BasicSpawnTunnel < AbstractTunnel
    def initialize(*abstract_args, spawn_args)
      @command = spawn_args.command

      super(*abstract_args, **spawn_args.options)
    end

    def get_and_write_ports(ssh, output)
      @command.set_dynamic_mode if @strategy.server_port.zero?

      @channel =
        ssh.open_channel do |ch|
          ch.exec @command.to_cmd do |_, success|
            raise SpawnError, 'could not spawn host' unless success

            # it is already triggered if the port is set
            get_remote_server_port(ch) if @command.dynamic?
          end
        end

      ssh.loop { !@channel[:triggered] } if @command.dynamic?
      @channel.eof!

      super
    end

    def get_remote_server_port(ch)
      ch[:data] = ''
      ch[:triggered] = false

      ch.on_data { |_, data| ch[:data] << data }
      ch.on_extended_data { |_, _, data| @server.log.error(data.inspect) }

      ch.on_process do |_|
        if !ch[:triggered] && ch[:data] =~ /Running on port (\d+)\./
          @strategy.instance_variable_set(:@server_port, $~[1])
          ch[:triggered] = true
        end
      end
    end

    def wait(ssh)
      ssh.loop { @channel.active? }
    end
  end
end
