
module Dirby
  class RefinedProtocol
    def initialize(regex, &block)
      @regex = regex
      @block = block
    end

    attr_reader :regex

    def call(*args)
      @block.call(*args)
    end
  end

  module BasicProtocol
    module ClassMethods
      attr_reader :scheme

      def get_refinement(type)
        instance_variable_get(:"@#{type}_refined") rescue nil
      end

      protected

      attr_writer :scheme

      def refine(type, regex, &block)
        instance_variable_set(:"@#{type}_refined", RefinedProtocol.new(regex, &block))
      end
    end

    def self.included(base)
      base.extend ClassMethods
      ProtocolMgr.add_protocol(base)
    end
  end
end
