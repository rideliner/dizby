
require 'dirby/basics'
require 'dirby/delegate'

require 'socket'
require 'tempfile'

raise LoadError, 'UNIXServer is required' unless defined?(UNIXServer)

module Dirby
  class UnixProtocol
    include BasicProtocol

    self.scheme = 'drbunix'

    self.regex = /^#{self.scheme}:(?<filename>.*)/

    def self.open_server(front, config, filename)
      Server.new front, config, filename
    end

    def self.open_client(server, filename)
      socket = UNIXSocket.open(filename)
      UnixProtocol.set_sockopt(socket)

      BasicClient.new server, socket, "#{self.scheme}:#{filename}"
    end

    private

    def self.set_sockopt(soc)
      # no-op for now
    end

    class Server < BasicServer
      include PolymorphicDelegated

      def initialize(front, config, filename)
        if filename.empty?
          temp = Tempfile.new(%w[ dirby-unix .socket ])
          filename = temp.path
          temp.close!
        end

        soc = UNIXServer.open(filename)
        UnixProtocol.set_sockopt(soc)

        super("drbunix:#{filename}", front, soc, config)

        self.class.set_permissions(filename, config)
      end

      def close
        unless stream.nil?
          path = stream.path
          stream.close
          self.stream = nil

          log("unlinking #{path}")
          File.unlink(path)
        end

        close_shutdown_pipe
      end

      def accept
        s = super

        UnixProtocol.set_sockopt(s)
        BasicConnection.new(self, s)
      end

      private

      def self.set_permissions(filename, config)
        owner = config[:unix_owner]
        group = config[:unix_group]
        mode = config[:unix_mode]

        if owner || group
          require 'etc'
          owner = Etc.getpwnam(owner).uid if owner
          group = Etc.getgrnam(group).gid if group
          File.chown(owner, group, filename)
        end

        File.chmod(mode, filename) if mode
      end
    end
  end
end