# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'shellwords'

module Dizby
  class SpawnCommand
    TEMPLATE =
      "require'dizby/tunnel/spawned';Dizby::Spawned.%s('%s',%s){%s}".freeze

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
      # TODO: needs a lot of work...
      args = [@mode, @uri.shellescape, @config.inspect, @data.shellescape]
      [@ruby_cmd, '-e', %("#{TEMPLATE % args}")].join ' '
    end
    alias to_s to_cmd

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
