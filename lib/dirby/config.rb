
module Dirby
  module Configurable
    def config_reader(*args)
      args.each { |x|
        define_method(x) do
          instance_variable_get(:@config)[x]
        end
      }
    end

    def config_writer(*args)
      args.each { |x|
        define_method("#{x}=") do |value|
          instance_variable_get(:@config)[x] = value
        end
      }
    end

    def config_accessor(*args)
      config_reader(*args)
      config_writer(*args)
    end
  end
end