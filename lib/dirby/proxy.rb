
require 'dirby/registration'
require 'dirby/unknown'

module Dirby
  class ObjectProxy
    def initialize(conn, ref = nil)
      @ref = ref
      @conn = conn
    end

    def method_missing(msg_id, *a, &b)
      # DRb sends self instead of @ref because send_request used to call __drbref
      # on the argument and that no longer happens because it isn't necessary.
      @conn.server.log.debug("calling through proxy: #{msg_id} #{a}")
      @conn.send_request(@ref, msg_id, a, b)
      succ, result = @conn.recv_reply

      if succ
        result
      elsif result.is_a?(UnknownObject)
        raise result
      else
        result.set_backtrace(Dirby.proxy_backtrace(@conn.remote_uri, result) + caller)
        raise result
      end
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      method_missing(:respond_to?, msg_id, priv)
    end
  end

  # Move prepare_backtrace out of ObjectProxy to make one fewer overlapped method
  def self.proxy_backtrace(prefix, exception)
    exception.backtrace.reject { |trace|
      /`__send__'$/ =~ trace
    }.map { |trace|
      # TODO why do we only add the prefix if the trace doesn't start with drb?
      # What about the other schemes?
      /^\(drb:\/\// =~ trace ? trace : "#{prefix}#{trace}"
    }
  end

  class SemiObjectProxy
    def initialize(uri, ref)
      @uri = uri
      @ref = ref
    end

    def evaluate(server)
      # cut down on network times by using the object if it exists on a local server
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
