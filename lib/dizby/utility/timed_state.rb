# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  class TimedState
    def initialize(timeout)
      @timeout = timeout
      revive
    end

    def update
      previous = @last_update
      @last_update = Time.now.utc
      timediff = (@last_update - previous) * 1000

      @time += timediff
      progress if @time >= @timeout
    end

    def alive?
      @state != :dead
    end

    def revive
      @state = :active
      @time = 0
      @last_update = Time.now.utc
    end

    private

    def progress
      @time = 0
      @state =
        case @state
        when :active
          :inactive
        when :inactive
          :dead
        end
    end
  end
end
