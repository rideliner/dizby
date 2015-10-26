
module DRb
  module BasicProtocol
    module ClassMethods
      # noinspection RubyResolve
      attr_reader :scheme, :regex
      protected
      attr_writer :scheme, :regex
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end