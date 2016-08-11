# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  module Configurable
    def config_reader(*args)
      args.each do |method|
        define_method(method) do
          instance_variable_get(:@config)[method]
        end
      end
    end

    def config_writer(*args)
      args.each do |method|
        define_method("#{method}=") do |value|
          instance_variable_get(:@config)[method] = value
        end
      end
    end

    def config_accessor(*args)
      config_reader(*args)
      config_writer(*args)
    end
  end
end
