
require 'dizby/utility/classic_access'
require 'dizby/utility/delegator'
require 'dizby/utility/force_bind'

module Dizby
  module PolymorphicDelegated
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        intercepted = [base, Object, Kernel, BasicObject, InstanceMethods]
        intercepted = intercepted.map(&:instance_methods).inject(&:-)

        @__delegated_methods__ =
          intercepted.each_with_object({}) do |name, methods|
            methods[name.to_sym] = base.instance_method(name)
            base.send(:undef_method, name)
          end
      end
    end

    module ClassMethods
      include ClassicAttributeAccess

      def __delegated_methods__
        instance_variable_get(:@__delegated_methods__)
      end

      def method_added(name)
        return if [:method_missing, :initialize].include?(name)
        @__delegated_methods__[name] = instance_method(name)
        send(:undef_method, name)
        nil
      end
    end

    module InstanceMethods
      def __delegate__(name, delegator, *args, &block)
        unbound = self.class.__delegated_methods__[name]

        bound = Dizby.force_bind(delegator, unbound)

        bound.call(*args, &block)
      end

      def method_missing(name, *args, &block)
        args.unshift(self) if args.empty? || !args.first.is_a?(Delegator)

        __delegate__ name, *args, &block
      end

      def respond_to?(sym, _priv = false)
        super || self.class.__delegated_methods__.keys.include?(sym)
      end
    end
  end
end
