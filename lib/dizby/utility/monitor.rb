
require 'monitor'

module Dizby
  def self.monitor(obj)
    obj.extend(MonitorMixin)
    obj
  end
end
