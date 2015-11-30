
module Dirby
  def self.any_to_s(obj)
    "#{obj}:#{obj.class}"
  rescue
    '#<%s:0x%1x>' % [obj.class, obj.__id__]
  end
end
