# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  class IOBarrier
    def initialize(var)
      @var = var
      @orig = var.dup
    end

    def block
      @var.reopen(File::NULL)
    end

    def allow
      @var.reopen(@orig)
      @var.sync = true
    end
  end
end
