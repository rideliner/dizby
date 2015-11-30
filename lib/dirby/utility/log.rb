
module Dirby
  class Log
    def self.from_config(config, transformer = nil)
      new(config[:verbosity], config[:output], transformer)
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
      return nil if @error

      log(exception.inspect)
      exception.backtrace.each do |trace|
        log(trace)
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
end
