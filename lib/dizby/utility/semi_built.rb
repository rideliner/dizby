# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  class SemibuiltObject
    def initialize(klass, *args)
      @klass = klass
      @base_args = args
    end

    def with(*args, &block)
      @klass.new(*@base_args, *args, &block)
    end

    def done
      with
    end
  end
end
