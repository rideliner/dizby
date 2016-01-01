# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  module Access
    class List < Array
      def matches?(addr)
        any? { |entry| entry.matches?(addr) }
      end
    end
  end
end
