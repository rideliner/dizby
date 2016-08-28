# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# require the whole package, minimizes command length
require 'dizby'
require 'dizby/utility/io_barrier'

module Dizby
  class Spawned
    def self.static(uri, config, &block)
      handle_spawned(uri, config, block)
    end

    def self.dynamic(uri, config, &block)
      handle_spawned(uri, config, block) do |service|
        port = service.instance_variable_get(:@server).port
        $stdout.puts "Running on port #{port}."
      end
    end

    def self.handle_spawned(uri, config, origin)
      obj = obtain_object(&origin)

      Service.start(uri: uri, front: obj, **config) do |service|
        obj.define_singleton_method :__dizby_exit__ do
          service.close if service
        end

        yield service if block_given?
      end
    end

    def self.obtain_object(&origin)
      barriers = [$stdout, $stdin, $stderr].map { |io| IOBarrier.new(io) }

      barriers.each(&:block)

      origin.call
    ensure
      barriers.each(&:allow)
    end
  end
end
