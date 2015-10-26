
module DRb
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
        result = if @block
          perform_with_block
        else
          perform_without_block
        end

        succ = true

        if @msg_id == :to_ary && result.class == Array
          result = DistributedArray.new(result, @server)
        end
      rescue StandardError, ScriptError, Interrupt
        @server.log("!!!!!error: #{$!.message}")
        result = $!
      end

      [ succ, result ]
    end

    def method_name
      [ @obj, @msg_id ]
    end

    private

    def any_to_s(obj)
      obj.to_s + ":#{obj.class}"
    rescue
      sprintf('#<%s:0x%lx>', obj.class, obj.__id__)
    end

    def perform_with_block
      @obj.__send__(@msg_id, *@argv) do |*x|
        jump_error = nil
        begin
          if x.size == 1 && x[0].class == Array
            x[0] = DistributedArray.new(x[0], @server)
          end

          block_value = @block.call(*x)
        rescue LocalJumpError
          jump_error = $!
        end

        if jump_error
          case jump_error.reason
            when :break
              break(jump_error.exit_value)
            else
              raise jump_error
          end
        end

        block_value
      end
    end

    def perform_without_block
      if Proc == @obj && @msg_id == :__drb_yield
        if @argv.size == 1
          @argv
        else
          [@argv]
        end.collect(&@obj)[0]
      else
        @obj.__send__(@msg_id, *@argv)
      end
    end
  end
end