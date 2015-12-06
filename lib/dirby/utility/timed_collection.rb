
require 'dirby/utility/monitor'
require 'dirby/utility/timed_state'

module Dirby
  class InvalidIdentifier < RuntimeError; end

  class TimedCollection
    def initialize(timeout, step)
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
        start = Time.now
        sleep(@step)
        elapsed_ms = (Time.now - start) * 1000

        @states.synchronize do
          @states.each { |_, v| v.update(elapsed_ms) }
          @states.keep_if { |_, v| v.alive? }
        end
      end
    end
  end
end
