# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'logger'

module Dizby
  def self.create_logger(output: $stderr, level: Logger::ERROR, &transformer)
    log = Logger.new(output)

    default_formatter = Logger::Formatter.new
    log.formatter = proc do |severity, datetime, progname, msg|
      msg = transformer.call(msg) if transformer
      default_formatter.call(severity, datetime, progname, msg)
    end

    log.level = level

    log.define_singleton_method(:backtrace) do |exception|
      error(exception.inspect)
      exception.backtrace.each { |trace| error(trace) }
    end

    log
  end
end
