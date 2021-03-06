# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/basic'
require 'dizby/stream/client'
require 'dizby/stream/connection'
require 'dizby/server/basic'

require 'socket'
require 'tempfile'

raise LoadError, 'UNIXServer is required' unless defined?(UNIXServer)

module Dizby
  class UnixProtocol
    include BasicProtocol

    self.scheme = 'drbunix'

    refine(
      :server,
      "#{scheme}:%{file}?"
    ) do |args, (filename)|
      Server.new args, filename
    end

    refine(
      :client,
      "#{scheme}:%{file}%{query}?"
    ) do |_args, server, (filename, query)|
      socket = UNIXSocket.open(filename)
      UnixProtocol.apply_sockopt(socket)

      client = BasicClient.new server, socket, "#{scheme}:#{filename}"
      query &&= QueryRef.new(query)

      [client, query]
    end

    def self.apply_sockopt(_soc)
      # no-op for now
    end

    class Server < BasicServer
      def initialize(args, filename)
        unless filename
          temp = Tempfile.new(%w(dizby-unix .socket))
          filename = temp.path
          temp.close!
        end

        socket = UNIXServer.open(filename)
        UnixProtocol.apply_sockopt(socket)

        args.uri = "drbunix:#{filename}"
        super(args, socket)

        self.class.set_permissions(filename, args.config)
      end

      def close
        if stream
          path = stream.path
          stream.close
          self.stream = nil

          log.debug("unlinking #{path}")
          File.unlink(path)
        end

        close_shutdown_pipe
      end

      def accept
        socket = super

        UnixProtocol.apply_sockopt(socket)
        BasicConnection.new(self, socket)
      end

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
      private_class_method :set_permissions
    end
  end
end
