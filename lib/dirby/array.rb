
require 'dirby/object'
require 'dirby/dump'

module Dirby
  class DistributedArray
    def initialize(ary, server)
      @ary = ary.map { |obj|
        if obj.kind_of? UndumpableObject
          DistributedObject.new(obj, server)
        else
          begin
            Marshal.dump(obj)
            obj
          rescue
            DistributedObject.new(obj, server)
          end
        end
      }
    end

    def self._load(s)
      # noinspection RubyResolve
      Marshal::load(s)
    end

    def _dump(_)
      Marshal.dump(@ary)
    end
  end
end