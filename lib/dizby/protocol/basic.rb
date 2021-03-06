# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/protocol/manager'
require 'dizby/protocol/refined'

module Dizby
  module BasicProtocol
    module ClassMethods
      attr_reader :scheme

      def refinements
        @refinements ||= Hash.new(nil)
      end

      protected

      attr_writer :scheme

      def refine(type, regex, &block)
        refinements[type] = RefinedProtocol.new(regex, &block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      ProtocolManager.add_protocol(base)
    end
  end
end
