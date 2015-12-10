
require 'dirby/registration'
require 'dirby/unknown'

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

  class SemiObjectProxy
    def initialize(uri, ref)
      @uri = uri
      @ref = ref
    end

    def evaluate(server)
      # cut down on network times by using the object if it exists locally
      success, obj = Dirby.get_obj(@uri, @ref)

      if success
        server.log.debug("found local obj: #{obj.inspect}")
        obj
      else
        server.log.debug("creating proxy to #{@ref} on #{@uri}")
        client, = server.connect_to(@uri) # throw away the ref
        ObjectProxy.new(client, @ref)
      end
    end
  end
end
