
require 'drb/unknown'

module DRb
  class ObjectProxy
    def initialize(conn, ref = nil)
      @ref = ref
      @conn = conn
    end

    def method_missing(msg_id, *a, &b)
      # DRb sends self instead of @ref because send_request used to call __drbref
      # on the argument and that no longer happens because it isn't necessary.
      @conn.server.log "calling through proxy: #{msg_id} #{a}"
      @conn.send_request(@ref, msg_id, a, b)
      succ, result = @conn.recv_reply

      if succ
        result
      elsif result.is_a?(UnknownObject)
        raise result
      else
        result.set_backtrace(ProxiedBacktrace.new(@conn.remote_uri, result).to_a + caller)
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
  class ProxiedBacktrace
    def initialize(uri, result)
      @backtrace = begin
        prefix = "(#{uri})"
        bt = [ ]

        result.backtrace.each do |x|
          break if /`__send__'$/ =~ x
          if /^\(drb:\/\// =~ x
            bt.push(x)
          else
            bt.push(prefix + x)
          end
        end

        bt
      end
    end

    def to_a
      @backtrace
    end
  end

  class SemiObjectProxy
    def initialize(uri, ref)
      @uri = uri
      @ref = ref
    end

    def to_obj
      nil # TODO check if the object is hosted locally
    end

    def to_proxy(server)
      ObjectProxy.new(server.connect_to(@uri), @ref)
    end
  end
end
