# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'ipaddr'

module Dizby
  module Access
    class Entry
      def initialize(str, allowed)
        @allowed = allowed
        @access = access_pattern(str)
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

      def allow?
        @allowed
      end

      private

      def access_pattern(str)
        if str == '*' || str == 'all'
          [:all]
        elsif str.include?('*')
          [:name, pattern(str)]
        else
          [:ip, pattern(str)]
        end
      rescue ArgumentError
        [:name, pattern(str)]
      end

      def pattern(str)
        pattern = str
                  .split('.')
                  .map { |segment| segment == '*' ? '.+' : segment }
                  .join('\\.')

        /^#{pattern}$/
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
