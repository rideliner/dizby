
require 'dirby/error'
require 'dirby/utility/string'

module Dirby
  INSECURE_METHODS = [:__send__]

  def self.check_insecure_method(obj, msg_id)
    raise ArgumentError, "#{Dirby.any_to_s(msg_id)} is not a symbol" unless msg_id.is_a?(Symbol)
    raise SecurityError, "insecure method `#{msg_id}'" if INSECURE_METHODS.include?(msg_id)

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
