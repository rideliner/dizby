# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  module ClassicAttributeAccess
    def attr_reader(*args)
      args.each do |method|
        define_method(method) do
          instance_variable_get(:"@#{method}")
        end
      end
    end

    def attr_writer(*args)
      args.each do |method|
        define_method("#{method}=") do |value|
          instance_variable_set(:"@#{method}", value)
        end
      end
    end

    def attr_accessor(*args)
      attr_reader(*args)
      attr_writer(*args)
    end
  end
end
