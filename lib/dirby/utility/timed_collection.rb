
require 'dirby/utility/monitor'
require 'dirby/utility/timed_state'

module Dirby
  class InvalidIdentifier < RuntimeError; end

  class TimedCollection
    def initialize(timeout, step = timeout)
      @timeout = timeout
      @step = [timeout, step].min # don't allow a larger step than timeout
      @states = Dirby.monitor({})
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
