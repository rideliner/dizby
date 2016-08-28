# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/self_pipe'

module Dizby
  class ShutdownPipe
    def initialize
      @pipe = SelfPipe.new(*IO.pipe)
    end

    def shutdown
      @pipe.close_write if @pipe
    end

    def shutdown?
      @pipe.write_closed?
    end

    def close
      return unless @pipe

      @pipe.close_read
      @pipe.close_write

      @pipe = nil
    end

    def wait_or_raise(stream, error)
      readable, = IO.select([stream, @pipe.read])
      raise error if readable.include?(@pipe.read)
    rescue IOError
      raise error
    end
  end
end
