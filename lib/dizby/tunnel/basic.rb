# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'dizby/tunnel/abstract'

module Dizby
  class BasicTunnel < AbstractTunnel
    def initialize(server, strategy, user, host)
      @working = true

      super(server, strategy, user, host)
    end

    def wait(ssh)
      ssh.loop { @working }
    end

    def close # TODO: test this
      @working = false
      super
    end
  end
end
