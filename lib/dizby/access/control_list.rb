# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/access/entry'

module Dizby
  module Access
    class ControlList
      def initialize
        @list = []
        deny_by_default
      end

      def allow_socket?(soc)
        allow_addr?(soc.peeraddr)
      end

      def allow_addr?(addr)
        match(addr).allow?
      end

      def allow(*addr)
        @list += addr.map { |a| Entry.new(a, true) }
      end

      def deny(*addr)
        @list += addr.map { |a| Entry.new(a, false) }
      end

      def allow_by_default
        self.default = true
      end

      def deny_by_default
        self.default = false
      end

      private

      def match(addr)
        @list.find { |entry| entry.matches?(addr) } || @default
      end

      def default=(default)
        @default = Entry.new('', default)
      end
    end
  end
end
