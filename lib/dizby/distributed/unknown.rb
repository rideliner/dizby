# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/error'

module Dizby
  class UnknownObject
    def initialize(err, buf)
      @name =
        case err.to_s
        when /uninitialized constant (\S+)/
          $~[1]
        when %r{undefined class/module (\S+)}
          $~[1]
        end

      @buf = buf
    end

    attr_reader :name, :buf

    def self._load(str)
      Marshal.load(str)
    rescue NameError, ArgumentError
      UnknownObject.new($!, str)
    end

    def _dump(_)
      Marshal.dump(@buf)
    end

    def reload
      self.class._load @buf
    end

    def exception
      UnknownObjectError.new self
    end
  end

  class UnknownObjectError < DistributedError
    def initialize(unknown)
      @unknown = unknown
      super unknown.name
    end

    # give access to the UnknownObject class
    attr_reader :unknown

    def self._load(str)
      Marshal.load(str)
    end

    def _dump(_)
      Marshal.dump(@unknown)
    end
  end
end
