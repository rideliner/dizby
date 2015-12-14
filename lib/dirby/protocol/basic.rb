
require 'dirby/protocol/manager'
require 'dirby/protocol/refined'

module Dirby
  module BasicProtocol
    module ClassMethods
      attr_reader :scheme

      def get_refinement(type)
        instance_variable_get(:"@#{type}_refined")
      rescue NameError
        nil
      end

      protected

      attr_writer :scheme

      def refine(type, regex, &block)
        refined = RefinedProtocol.new(regex, &block)
        instance_variable_set(:"@#{type}_refined", refined)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      ProtocolManager.add_protocol(base)
    end
  end
end
