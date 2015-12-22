
require 'dizby/distributed/array'

module Dizby
  class InvokeMethod
    def initialize(server, obj, msg, argv, block)
      @obj = obj
      @msg_id = msg.intern
      @argv = argv
      @block = block && proc { |*args| call_block(block, *args) }

      @server = server
    end

    def perform
      result = send_to_object

      # TODO: do we care what the @msg_id is?
      # Should we convert to a DistributedArray regardless?
      if @msg_id == :to_ary && result.class == Array
        result = DistributedArray.new(result, @server)
      end

      [true, result]
    rescue StandardError, ScriptError, Interrupt
      @server.log.backtrace($!)
      [false, $!]
    end

    private

    def call_block(block, *args)
      if args.size == 1 && args[0].is_a?(Array)
        args[0] = DistributedArray.new(args[0], @server)
      end

      block.call(*args)
    rescue LocalJumpError
      handle_jump_error($!)
    end

    def handle_jump_error(err)
      case err.reason
      when :break
        err.exit_value
      else
        fail err
      end
    end

    def send_to_object
      @obj.__send__(@msg_id, *@argv, &@block)
    end
  end
end
