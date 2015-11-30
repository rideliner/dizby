
require 'dirby/object'
require 'dirby/dump'

module Dirby
  class DistributedArray
    def initialize(ary, server)
      @ary = ary.map do |obj|
        if obj.is_a? UndumpableObject
          DistributedObject.new(obj, server)
        else
          begin
            Marshal.dump(obj)
            obj
          rescue
            DistributedObject.new(obj, server)
          end
        end
      end
    end

    def self._load(s)
      Marshal.load(s)
    end

    def _dump(_)
      Marshal.dump(@ary)
    end
  end
end
