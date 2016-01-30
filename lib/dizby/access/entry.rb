# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'ipaddr'

module Dizby
  module Access
    class Entry
      def initialize(str)
        if str == '*' || str == 'all'
          @access = [:all]
        elsif str.include?('*')
          @access = [:name, pattern(str)]
        else
          begin
            @access = [:ip, IPAddr.new(str)]
          rescue ArgumentError
            @access = [:name, pattern(str)]
          end
        end
      end

      def matches?(addr)
        (scope, pattern) = @access

        case scope
        when :all
          true
        when :ip
          matches_ip?(addr, pattern)
        when :name
          matches_name?(addr, pattern)
        else
          false
        end
      end

      class << self
        private

        def pattern(str)
          pattern = str.split('.')
          pattern.map! { |segment| (segment == '*') ? '.+' : segment }
          /^#{pattern.join('\\.')}$/
        end

        def matches_ip?(addr, pattern)
          ipaddr = IPAddr.new(addr[3])
          # map to ipv6 if entry is ipv6 and address is ipv4
          ipaddr = ipaddr.ipv4_mapped if pattern.ipv6? && ipaddr.ipv4?

          pattern.include?(ipaddr)
        rescue ArgumentError
          false
        end

        def matches_name?(addr, pattern)
          pattern =~ addr[2]
        end
      end
    end
  end
end
