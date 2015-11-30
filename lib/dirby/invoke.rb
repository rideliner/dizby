
require 'dirby/array'

module Dirby
  class InvokeMethod
    def initialize(server, obj, msg, argv, block)
      @obj = obj
      @msg_id = msg.intern
      @argv = argv
      @block = block

      @server = server
    end

    def perform
      result = nil
      succ = false

      begin
        result =
          if @block
            perform_with_block
          else
            perform_without_block
          end

        succ = true

        # TODO: do we care what the @msg_id is? Should we convert to a DistributedArray regardless?
        if @msg_id == :to_ary && result.class == Array
          result = DistributedArray.new(result, @server)
        end
      rescue StandardError, ScriptError, Interrupt
        @server.log.backtrace($!)
        result = $!
      end

      [succ, result]
    end

    def method_name
      [@obj, @msg_id]
    end

    private

    def perform_with_block
      @obj.__send__(@msg_id, *@argv) do |*args|
        jump_error = nil
        begin
          if args.size == 1 && args[0].class == Array
            args[0] = DistributedArray.new(args[0], @server)
          end

          block_value = @block.call(*args)
        rescue LocalJumpError
          jump_error = $!
        end

        if jump_error
          case jump_error.reason
          when :break
            break jump_error.exit_value
          else
            raise jump_error
          end
        end

        block_value
      end
    end

    def perform_without_block
      @obj.__send__(@msg_id, *@argv)
    end
  end
end
