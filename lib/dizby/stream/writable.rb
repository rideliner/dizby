# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/distributed/undumpable'

module Dizby
  module WritableStream
    def write(data)
      @stream.write(data)
    end

    def dump_data(obj, error = false)
      @server.log.debug("dumping: #{obj.inspect}")

      if obj.is_a?(UndumpableObject)
        @server.log.debug('dumping undumpable')
        obj = make_distributed(obj, error)
      end

      str = dump_obj(obj, error)
      @server.log.debug("dumped: #{str.inspect}")

      [str.size].pack('N') + str
    end

    private

    def dump_obj(obj, error)
      Marshal.dump(obj)
    rescue
      @server.log.debug('rescuing and dumping pseudo-undumpable...')
      Marshal.dump(make_distributed(obj, error))
    end

    def make_distributed(obj, error)
      @server.make_distributed(obj, error)
    end
  end
end
