
module Dizby
  class SemibuiltObject
    def initialize(klass, *args)
      @klass = klass
      @base_args = args
    end

    def with(*args, &block)
      @klass.new(*@base_args, *args, &block)
    end

    def done
      with
    end
  end
end