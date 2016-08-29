# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/distributed/object'
require 'dizby/distributed/undumpable'

module Dizby
  class DistributedArray
    def initialize(ary, server)
      @ary = ary.map { |obj| self.class.distribute_if_necessary(obj, server) }
    end

    def self.distribute_if_necessary(obj, server)
      Marshal.dump(obj)
    rescue
      server.make_distributed(obj, false)
    else
      obj
    end
    private_class_method :distribute_if_necessary

    def self._load(str)
      Marshal.load(str)
    end

    def _dump(_)
      Marshal.dump(@ary)
    end
  end
end
