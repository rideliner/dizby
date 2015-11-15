
require 'net/ssh'

# TODO split into smaller methods

module Dirby
  class AbstractTunnel
    def initialize(client_port, server_port)
      @client_port = client_port
      @server_port = server_port
    end

    def open(ssh)
      [ create_local_tunnel(ssh), create_remote_tunnel(ssh) ]
    end

    def create_local_tunnel(ssh)
      ssh.forward.local 0, 'localhost', @server_port
    end

    def create_remote_tunnel(ssh)
      ssh.forward.remote @client_port, 'localhost', 0, 'localhost'
      remote_ports = ssh.forward.instance_variable_get :@remote_forwarded_ports

      remote_tunnel_port = nil

      ssh.loop {
        remote_tunnel_port = remote_ports.select { |_, v| v.port == @client_port }
        remote_tunnel_port.empty?
      }

      remote_tunnel_port.keys.first.first
    end
  end

  class BasicTunnel
    def initialize(user, host, server_port, client_port, ssh_config)
      config = [ user, host, ssh_config ]

      @working = true
      begin
        reader, writer = IO.pipe

        @thread = Thread.new(writer) do |out|
          tunnel = AbstractTunnel.new(client_port, server_port)
          ssh = nil
          begin
            ssh = Net::SSH.start *config

            out.puts *tunnel.open(ssh)

            ssh.loop { @working }
          ensure
            ssh.close unless ssh.nil?
          end
        end

        @thread.abort_on_exception = true

        @local_port = reader.gets.chomp.to_i
        @remote_port = reader.gets.chomp.to_i
      end
    end

    def close # TODO test this
      @working = false
      @thread.join
    end
  end

  class SpawnTunnel # TODO not tested at all
    def initialize(command, user, host, client_port, ssh_config)
      raise Exception, '' unless command.is_a?(SpawnCommand) # TODO message

      config = [ user, host, ssh_config ]

      begin
        reader, writer = IO.pipe

        @thread = Thread.new(writer) do |out|
          ssh = nil
          server_port = nil

          begin
            ssh = Net::SSH.start *config

            channel = ssh.open_channel { |ch|
              ch.exec command.to_cmd do |_, success|
                ch[:triggered] = false
                ch[:data] = ''

                # TODO better exception class
                raise Exception, 'could not spawn host' unless success

                ch.on_data { |_, data|
                  ch[:data] << data
                }

                ch.on_extended_data { |_, _, data|
                  $stderr.puts data.inspect
                }

                ch.on_process { |_|
                  if !ch[:triggered] && ch[:data] =~ /Running on port (\d+)/
                    server_port = $1
                    ch[:triggered] = true
                  end
                }
              end
            }

            ssh.loop { !channel[:triggered] }
            channel.eof!

            tunnel = AbstractTunnel.new(client_port, server_port)
            out.puts *tunnel.open(ssh)

            ssh.loop { channel.active? }
          ensure
            ssh.close unless ssh.nil?
          end
        end

        @thread.abort_on_exception = true

        @local_port = reader.gets.chomp.to_i
        @remote_port = reader.gets.chomp.to_i
      end
    end

    def close
      @thread.join
    end
  end
end
