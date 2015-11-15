
module Dirby
  def self.any_to_s(obj)
    "#{obj.to_s}:#{obj.class}"
  rescue
    '#<%s:0x%lx>' % [ obj.class, obj.__id__ ]
  end
end