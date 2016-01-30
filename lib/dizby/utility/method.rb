# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  def self.caller
    caller_locations(2, 1).first.label
  end

  def self.method_visibility(obj, method)
    if obj.public_method_defined? method
      :public
    elsif obj.private_method_defined? method
      :private
    elsif obj.protected_method_defined? method
      :protected
    end
  end

  def self.set_method_visibility(obj, method, visibility)
    obj.__send__ visibility, method
  end

  def self.redefine_method(obj, name, &block)
    visibility = Dizby.method_visibility(obj, name)
    obj.__send__(:undef_method, name)
    obj.__send__(:define_method, name, &block)
    Dizby.set_method_visibility(obj, name, visibility)
  end
end
