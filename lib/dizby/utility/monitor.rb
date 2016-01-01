# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'monitor'

module Dizby
  def self.monitor(obj)
    obj.extend(MonitorMixin)
    obj
  end
end
