
module Dirby
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
