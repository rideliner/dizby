
require 'drb/proxy'
require 'drb/registration'

module DRb
  class DistributedObject
    def self._load(s)
      SemiObjectProxy.new(*Marshal.load(s))
    end

    def _dump(_)
      Marshal.dump [ @server.uri, @server.to_id(@obj) ]
    end

    def initialize(obj, server)
      @obj = obj
      @server = server
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      x = case msg_id
        when :_dump
          true
        when :marshal_dump
          false
        else
          method_missing(:respond_to?, msg_id, priv)
      end

      @server.log("respond_to?(#{msg_id}) => #{x}")
      x
    end

    def method_missing(msg_id, *a, &b)
      # TODO check insecure method
      @server.log("calling: #{msg_id} #{a.join ', '}")
      @obj.__send__(msg_id, *a, &b)
    end
  end

  class RemoteDistributedObject
    def initialize(d_obj, remote_uri)
      @distributed_obj = d_obj
      @remote_uri = remote_uri
    end

    #attr_reader :remote_uri, :distributed_obj

    def self._load(s)
      (uri, ref), remote_uri = *Marshal.load(s)
      #uri, ref = *Marshal.load(obj)

      ObjectProxy.new(DRb.find_server(remote_uri).connect_to(uri), ref)
    end

    def _dump(_)
      s = Marshal.dump [ @distributed_obj, @remote_uri ]
      # p s
      s
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      @distributed_obj.respond_to?(msg_id, priv)
    end

    def method_missing(msg_id, *a, &b)
      @distributed_obj.method_missing(msg_id, *a, &b)
    end
  end
end
