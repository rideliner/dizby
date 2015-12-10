
require 'shellwords'

module Dirby
  class SpawnCommand
    TEMPLATE = "require'dirby/spawned';Dirby.handle_%s_spawned('%s','%s',begin;%s;end)"

    def initialize(data, config = {})
      @data = data
      @ruby_cmd = 'ruby'
      @uri = 'drb://'
      @config = config
      @mode = :static
    end

    def set_dynamic_mode
      @mode = :dynamic
    end

    def dynamic?
      @mode == :dynamic
    end

    attr_accessor :ruby_cmd, :config, :uri

    def to_cmd
      template_args = [@mode, @uri, Marshal.dump(@config), @data].shelljoin
      [@ruby_cmd, '-e', TEMPLATE % template_args].shelljoin
    end
    alias_method :to_s, :to_cmd

    class << self
      def text(script)
        new(script)
      end

      def local_file(file)
        new(File.read(file))
      end

      # WARNING: Dangerous operation. This loads an object from a file on the
      # remote machine. That file may be insecure or modified without notice.
      def remote_file(file, obj_name)
        new("load '#{file}'; #{obj_name}")
      end
    end
  end
end
