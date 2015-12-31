
require 'dizby/error'

module Dizby
  class UnknownObject
    def initialize(err, buf)
      case err.to_s
      when /uninitialized constant (\S+)/
        @name = $~[1]
      when %r{undefined class/module (\S+)}
        @name = $~[1]
      else
        @name = nil
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