# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

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
