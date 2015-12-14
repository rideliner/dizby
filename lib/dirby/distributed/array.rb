
require 'dirby/distributed/object'
require 'dirby/distributed/undumpable'

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

    def self._load(str)
      Marshal.load(str)
    end

    def _dump(_)
      Marshal.dump(@ary)
    end
  end
end
