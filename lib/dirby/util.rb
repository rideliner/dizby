
module Dirby
  def self.any_to_s(obj)
    "#{obj.to_s}:#{obj.class}"
  rescue
    '#<%s:0x%lx>' % [ obj.class, obj.__id__ ]
  end

  class Log
    def self.from_config(config, transformer = nil)
      self.new(config[:verbosity], config[:output], transformer)
    end

    def initialize(verbosity, output, transformer = nil)
      @output = output

      @debug = verbosity == :debug
      @info = @debug || verbosity == :info
      @error = @info || verbosity == :error

      @transformer = transformer
    end

    def info(msg)
      log(msg) if @info
    end

    def debug(msg)
      log(msg) if @debug
    end

    def error(msg)
      log(msg) if @error
    end

    def backtrace(exception)
      if @error
        log(exception.inspect)
        exception.backtrace.each do |trace|
          log(trace)
        end
      end
    end

    private

    def log(msg)
      @output.puts transform(msg)
    end

    def transform(msg)
      @transformer.nil? ? msg : @transformer.log_message(msg)
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