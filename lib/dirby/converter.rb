
require 'dirby/utility/timed_collection'

module Dirby
  class IdConverter
    def self.to_obj(ref)
      ObjectSpace._id2ref(ref)
    end

    def self.to_id(obj)
      obj.__id__
    end
  end

  class TimedIdConverter
    # default timeout: 10 minutes, default step: 30 seconds
    def initialize(timeout = 600_000, step = 30_000)
      @collection = TimedCollection.new(timeout, step)
    end

    def to_obj(ref)
      @collection.revive(ref)
      IdConverter.to_obj(ref)
    end

    def to_id(obj)
      key = IdConverter.to_id(obj)
      @collection.add(key)
      key
    end
  end
end
