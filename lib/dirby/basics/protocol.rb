
module Dirby
  module BasicProtocol
    module ClassMethods
      attr_reader :scheme, :regex
      protected
      attr_writer :scheme, :regex
    end

    def self.included(base)
      base.extend ClassMethods
      ProtocolMgr.add_protocol(base)
    end
  end
end