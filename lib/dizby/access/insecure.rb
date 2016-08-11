# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/utility/string'

module Dizby
  INSECURE_METHODS = [:__send__].freeze

  def self.check_insecure_method(obj, msg_id)
    unless msg_id.is_a?(Symbol)
      raise ArgumentError, "#{Dizby.any_to_s(msg_id)} is not a symbol"
    end

    if INSECURE_METHODS.include?(msg_id)
      raise SecurityError, "insecure method `#{msg_id}'"
    end

    check_hidden_method(obj, msg_id)
  end

  def self.check_hidden_method(obj, msg_id)
    if obj.private_methods.include?(msg_id)
      desc = Dizby.any_to_s(obj)
      raise NoMethodError, "private method `#{msg_id}' called for #{desc}"
    elsif obj.protected_methods.include?(msg_id)
      desc = Dizby.any_to_s(obj)
      raise NoMethodError, "protected method `#{msg_id}' called for #{desc}"
    else
      true
    end
  end
end
