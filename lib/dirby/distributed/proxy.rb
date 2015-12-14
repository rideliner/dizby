
require 'dirby/distributed/unknown'

module Dirby
  class ObjectProxy
    def initialize(conn, ref = nil)
      @ref = ref
      @conn = conn
    end

    def method_missing(msg_id, *args, &block)
      @conn.server.log.debug("calling through proxy: #{msg_id} #{args}")
      @conn.send_request(@ref, msg_id, *args, &block)
      succ, result = @conn.recv_reply

      if succ
        result
      elsif result.is_a?(UnknownObject)
        raise result
      else
        bt = Dirby.proxy_backtrace(@conn.remote_uri, result)
        result.set_backtrace(bt + caller)
        raise result
      end
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      method_missing(:respond_to?, msg_id, priv)
    end
  end

  def self.proxy_backtrace(prefix, exception)
    bt = exception.backtrace.reject { |trace| /`__send__'$/ =~ trace }
    bt.map { |trace| %r{\(drb://} =~ trace ? trace : "#{prefix}#{trace}" }
    # TODO: why do we only add the prefix if the trace doesn't start with drb?
    # What about the other schemes?
  end
end
