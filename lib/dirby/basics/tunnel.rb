
require 'dirby/tunnel/abstract'

module Dirby
  class BasicTunnel < AbstractTunnel
    def initialize(server, strategy, user, host)
      @working = true

      super(server, strategy, user, host)
    end

    def wait(ssh)
      ssh.loop { @working }
    end

    def close # TODO test this
      @working = false
      super
    end
  end

  class BasicSpawnTunnel < AbstractTunnel
    def initialize(server, strategy, command, user, host)
      @command = command

      super(server, strategy, user, host)
    end

    def get_and_write_ports(ssh, output)
      dynamic = @tunnel.server_port.nil?
      @command.set_dynamic_mode if dynamic

      @channel = ssh.open_channel { |ch|
        ch.exec @command.to_cmd do |_, success|
          raise SpawnError, 'could not spawn host' unless success

          # it is already triggered if the port is set
          ch[:triggered] = !dynamic
          get_remote_server_port(ch) if dynamic
        end
      }

      ssh.loop { !@channel[:triggered] }
      @channel.eof!

      super
    end

    def get_remote_server_port(ch)
      ch[:data] = ''

      ch.on_data { |_, data|
        ch[:data] << data
      }

      ch.on_extended_data { |_, _, data|
        @server.log(data.inspect)
      }

      ch.on_process { |_|
        if !ch[:triggered] && ch[:data] =~ /Running on port (\d+)/
          @strategy.instance_variable_set(:@server_port, $1)
          ch[:triggered] = true
        end
      }
    end

    def wait(ssh)
      ssh.loop { @channel.active? }
    end
  end
end
