
require 'dirby/command'

require 'net/ssh'

module Dirby
  class AbstractTunnel
    def initialize(server, strategy, user, host)
      @server = server
      @config = [ user, host, @server.config[:ssh_config] ]
      @strategy = strategy

      reader, writer = IO.pipe

      @thread = Thread.new do
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
        ssh = Net::SSH.start *@config

        get_and_write_ports(ssh, output)

        wait(ssh)
      ensure
        ssh.close unless ssh.nil?
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
      raise Exception, '' unless command.is_a?(SpawnCommand) # TODO message and move this out of here and into whoever creates the spawn tunnel...

      @command = command.to_cmd

      super(server, strategy, user, host)
    end

    def get_and_write_ports(ssh, output)
      @channel = ssh.open_channel { |ch|
        ch.exec @command do |_, success|
          ch[:triggered] = false
          ch[:data] = ''

          raise Exception, 'could not spawn host' unless success # TODO better exception class

          ch.on_data { |_, data|
            ch[:data] << data
          }

          ch.on_extended_data { |_, _, data|
            $stderr.puts data.inspect # any way to hook into server logging?
          }

          ch.on_process { |_|
            if !ch[:triggered] && ch[:data] =~ /Running on port (\d+)/
              @strategy.instance_variable_set(:@server_port, $1)
              ch[:triggered] = true
            end
          }
        end
      }

      ssh.loop { !@channel[:triggered] }
      @channel.eof!

      super
    end

    def wait(ssh)
      ssh.loop { @channel.active? }
    end
  end
end
