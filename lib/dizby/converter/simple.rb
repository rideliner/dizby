# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  class IdConverter
    def self.to_obj(ref)
      ObjectSpace._id2ref(ref)
    end

    def self.to_id(obj)
      obj.__id__
    end
  end
end
