
module DRb
  module ClassicAttributeAccess
    def attr_reader(*args)
      args.each { |x|
        define_method(x) do
          instance_variable_get(:"@#{x}")
        end
      }
    end

    def attr_writer(*args)
      args.each { |x|
        define_method("#{x}=") do |value|
          instance_variable_set(:"@#{x}", value)
        end
      }
    end

    def attr_accessor(*args)
      attr_reader(*args)
      attr_writer(*args)
    end
  end

  class Delegator
    def initialize(obj)
      @__delegated_object__ = obj
    end

    def instance_variable_get(sym)
      @__delegated_object__.instance_variable_get(sym)
    end

    def instance_variable_set(sym, value)
      @__delegated_object__.instance_variable_set(sym, value)
    end

    def __undelegated_get__(sym)
      __instance_variable_get__(sym)
    end

    def __undelegated_set__(sym, value)
      __instance_variable_set__(sym, value)
    end

    def method_missing(name, *args, &block)
      @__delegated_object__.__delegate__(name, self, *args, &block)
    end
  end

  module PolymorphicDelegated
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        intercepted = [ base, Object, Kernel, BasicObject, InstanceMethods ]
        intercepted = intercepted.map(&:instance_methods).inject(&:-)

        @__delegated_methods__ = intercepted.inject(Hash.new) do |methods, method_name|
          methods[method_name.to_sym] = base.instance_method(method_name)
          base.send(:undef_method, method_name)
          methods
        end
      end
    end

    module ClassMethods
      include ClassicAttributeAccess

      def __delegated_methods__
        instance_variable_get(:@__delegated_methods__)
      end

      def method_added(name)
        return if [ :method_missing, :initialize ].include?(name)
        @__delegated_methods__[name] = self.instance_method(name)
        self.send(:undef_method, name)
        nil
      end
    end

    module InstanceMethods
      def __delegate__(name, delegator, *args, &block)
        m = self.class.__delegated_methods__[name]

        Method.new(delegator, m.defined_in, m.executable, m.name).call(*args, &block)
      end

      def method_missing(name, *args, &block)
        args.unshift(self) if args.empty? || !args.first.is_a?(Delegator)

        __delegate__ name, *args, &block
      end

      def respond_to?(sym, _ = false)
        super || self.class.__delegated_methods__.keys.include?(sym)
      end
    end
  end
end
