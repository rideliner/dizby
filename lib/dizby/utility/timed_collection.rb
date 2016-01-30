# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/monitor'
require 'dizby/utility/timed_state'

module Dizby
  class InvalidIdentifier < RuntimeError; end

  class TimedCollection
    def initialize(timeout, step = timeout)
      @timeout = timeout
      @step = [timeout, step].min # don't allow a larger step than timeout
      @states = Dizby.monitor({})
      @updater = Thread.start { update }
    end

    def revive(id)
      @states.synchronize { @states.fetch(id).revive }
    rescue KeyError
      raise InvalidIdentifier, 'identifier timed out or did not exist'
    end

    def add(id)
      @states.synchronize { @states[id] = TimedState.new(@timeout) }
    end

    private

    def update
      loop do
        sleep(@step)

        @states.synchronize do
          @states.each_value(&:update)
          @states.keep_if { |_, state| state.alive? }
        end
      end
    end
  end
end
