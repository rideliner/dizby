
require 'shellwords'

module Dirby
  class SpawnCommand
    TEMPLATE = "require'dirby/spawned';Dirby.handle_%s_spawned('%s','%s',begin;%s;end)"

    def initialize(data, config = { })
      @data = data
      @ruby_cmd = 'ruby'
      @uri = 'drb://'
      @config = config
      @mode = :static
    end

    # the uri must point to a protocol that allows a server to be
    # created and for a port to be accessed from that server.
    def uri=(uri) # should this be checked here or on the remote server?
      # TODO
      @uri = uri
    end

    def set_dynamic_mode
      @mode = :dynamic
    end

    attr_reader :uri
    attr_accessor :ruby_cmd, :config

    def to_cmd
      template_args = [ @mode, @uri, Marshal.dump(@config), @data ].shelljoin
      [ @ruby_cmd, '-e', TEMPLATE % template_args ].shelljoin
    end
    alias_method :to_s, :to_cmd

    class << self
      def text(script)
        self.new(script)
      end

      def local_file(file)
        self.new File.read(file)
      end

      # WARNING: Dangerous operation. This loads an object from a file on the
      # remote machine. That file may be insecure or modified without notice.
      def remote_file(file, obj_name)
        self.new "load '#{file}'; #{obj_name}"
      end
    end
  end
end
