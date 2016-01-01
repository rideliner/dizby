# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

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
