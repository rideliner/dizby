
module Dirby
  module ClassicAttributeAccess
    def attr_reader(*args)
      args.each { |method|
        define_method(method) do
          instance_variable_get(:"@#{method}")
        end
      }
    end

    def attr_writer(*args)
      args.each { |method|
        define_method("#{method}=") do |value|
          instance_variable_set(:"@#{method}", value)
        end
      }
    end

    def attr_accessor(*args)
      attr_reader(*args)
      attr_writer(*args)
    end
  end
end