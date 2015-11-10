
module Dirby
  def self.any_to_s(obj)
    "#{obj.to_s}:#{obj.class}"
  rescue
    '#<%s:0x%lx>' % [ obj.class, obj.__id__ ]
  end

  module Loggable
    # Requires the `debug` method which take 0 parameters
    def log(msg)
      if debug
        if debug.is_a?(IO)
          debug << msg
        else
          puts msg
        end
      end
    end
  end

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
  # TODO what else fits in this file?
end