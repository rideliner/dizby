# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  class SpawnCommand
    TEMPLATE =
      "require'dizby/tunnel/spawned';Dizby::Spawned.%s('%s',%s){%s}".freeze

    def initialize(data, **config)
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
      <<~EOF
        #{@ruby_cmd} -e "$(cat <<DIZBY
        #{format(TEMPLATE, @mode, @uri, @config.inspect, @data)}
        DIZBY
        )"
      EOF
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
