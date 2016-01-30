# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/classic_access'
require 'dizby/utility/delegator'
require 'dizby/utility/force_bind'
require 'dizby/utility/method'

module Dizby
  module PolymorphicDelegated
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        intercepted = [base, Object, Kernel, BasicObject]
        intercepted = intercepted.map(&:instance_methods).reduce(&:-)

        intercepted.each do |name|
          __create_delegated_method__(name)
        end
      end
    end

    module ClassMethods
      include ClassicAttributeAccess

      def __create_delegated_method__(name)
        method = instance_method(name)

        Dizby.redefine_method(self, name) do |*args, &block|
          delegator =
            if args.empty? || !args.first.is_a?(Delegator)
              self
            else
              args.shift
            end

          bound = Dizby.force_bind(delegator, method)
          bound.call(*args, &block)
        end
      end

      def method_added(name)
        return if %i(method_missing initialize).include?(name)
        return if %w(redefine_method define_method).include?(Dizby.caller)

        __create_delegated_method__(name)
      end
    end
  end
end
