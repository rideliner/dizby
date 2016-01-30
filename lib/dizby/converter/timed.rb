# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/timed_collection'
require 'dizby/converter/simple'

module Dizby
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
