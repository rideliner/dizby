
require 'dirby/utility/timed_collection'
require 'dirby/converter/simple'

module Dirby
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
