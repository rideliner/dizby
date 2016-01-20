# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'logger'

module Dizby
  class Logger < ::Logger
    def initialize(output: $stderr, level: Logger::ERROR, &transformer)
      super(output)

      self.formatter = self.class.transform_formatter(&transformer)
      self.level = level
    end

    def backtrace(exception)
      error(exception.inspect)
      exception.backtrace.each { |trace| error(trace) }
    end

    def self.transform_formatter(&transformer)
      default_formatter = Logger::Formatter.new
      proc do |severity, datetime, progname, msg|
        msg = transformer.call(msg) if transformer
        default_formatter.call(severity, datetime, progname, msg)
      end
    end
  end
end
