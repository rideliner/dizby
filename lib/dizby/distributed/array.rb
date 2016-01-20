# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'dizby/distributed/object'
require 'dizby/distributed/undumpable'

module Dizby
  class DistributedArray
    def initialize(ary, server)
      @ary =
        ary.map do |obj|
          if obj.is_a? UndumpableObject
            DistributedObject.new(obj, server)
          else
            self.class.distribute_if_necessary(obj)
          end
        end
    end

    def self.distribute_if_necessary(obj)
      Marshal.dump(obj)
    rescue
      DistributedObject.new(obj, server)
    else
      obj
    end

    def self._load(str)
      Marshal.load(str)
    end

    def _dump(_)
      Marshal.dump(@ary)
    end
  end
end
