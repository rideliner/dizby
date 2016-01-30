# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
