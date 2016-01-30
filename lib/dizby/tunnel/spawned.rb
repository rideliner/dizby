# encoding: utf-8
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
        $stdout.puts "Running on port #{service.server.port}."
      end
    end

    def self.handle_spawned(uri, config, origin)
      service = nil

      obj = obtain_object(&origin)

      obj.define_singleton_method :__dizby_exit__ do
        service.close if service
      end

      service = Service.new(uri, obj, Marshal.load(config))
      yield service if block_given?
    ensure
      service.wait if service
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
