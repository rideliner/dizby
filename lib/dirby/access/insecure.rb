
require 'dirby/utility/string'

module Dirby
  INSECURE_METHODS = [:__send__]

  def self.check_insecure_method(obj, msg_id)
    unless msg_id.is_a?(Symbol)
      raise ArgumentError, "#{Dirby.any_to_s(msg_id)} is not a symbol"
    end

    if INSECURE_METHODS.include?(msg_id)
      raise SecurityError, "insecure method `#{msg_id}'"
    end

    check_hidden_method(obj, msg_id)
  end

  def self.check_hidden_method(obj, msg_id)
    if obj.private_methods.include?(msg_id)
      desc = Dirby.any_to_s(obj)
      raise NoMethodError, "private method `#{msg_id}' called for #{desc}"
    elsif obj.protected_methods.include?(msg_id)
      desc = Dirby.any_to_s(obj)
      raise NoMethodError, "protected method `#{msg_id}' called for #{desc}"
    else
      true
    end
  end
end
