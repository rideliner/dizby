
module Dirby
  class TimedState
    def initialize(timeout)
      @timeout = timeout
      revive
    end

    def update(timediff)
      @time += timediff
      progress if @time >= @timeout
    end

    def alive?
      @state != :dead
    end

    def revive
      @state = :active
      @time = 0
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
