
require 'monitor'

module Dirby
  def self.monitor(obj)
    obj.extend(MonitorMixin)
    obj
  end
end
