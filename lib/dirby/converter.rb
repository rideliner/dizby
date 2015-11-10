
module Dirby
  class IdConverter
    def self.to_obj(ref)
      ObjectSpace._id2ref(ref)
    end

    def self.to_id(obj)
      obj.nil? ? nil : obj.__id__
    end
  end

  class TimedIdConverter
    # TODO maybe??
  end
end