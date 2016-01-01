# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'dizby/utility/string'

module Dizby
  INSECURE_METHODS = [:__send__]

  def self.check_insecure_method(obj, msg_id)
    unless msg_id.is_a?(Symbol)
      fail ArgumentError, "#{Dizby.any_to_s(msg_id)} is not a symbol"
    end

    if INSECURE_METHODS.include?(msg_id)
      fail SecurityError, "insecure method `#{msg_id}'"
    end

    check_hidden_method(obj, msg_id)
  end

  def self.check_hidden_method(obj, msg_id)
    if obj.private_methods.include?(msg_id)
      desc = Dizby.any_to_s(obj)
      fail NoMethodError, "private method `#{msg_id}' called for #{desc}"
    elsif obj.protected_methods.include?(msg_id)
      desc = Dizby.any_to_s(obj)
      fail NoMethodError, "protected method `#{msg_id}' called for #{desc}"
    else
      true
    end
  end
end
