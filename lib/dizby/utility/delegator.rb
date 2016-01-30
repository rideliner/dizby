# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  class Delegator
    def initialize(obj)
      @__delegated_object__ = obj
    end

    def instance_variable_get(sym)
      @__delegated_object__.instance_variable_get(sym)
    end

    def instance_variable_set(sym, value)
      @__delegated_object__.instance_variable_set(sym, value)
    end

    def __undelegated_get__(sym)
      __instance_variable_get__(sym)
    end

    def __undelegated_set__(sym, value)
      __instance_variable_set__(sym, value)
    end

    def method_missing(name, *args, &block)
      @__delegated_object__.__delegate__(name, self, *args, &block)
    end
  end
end
