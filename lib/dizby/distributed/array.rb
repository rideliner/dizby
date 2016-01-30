# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
