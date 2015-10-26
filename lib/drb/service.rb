
require 'drb/registration'
require 'drb/manager'
require 'drb/proxy'
require 'drb/converter'
require 'drb/error'
require 'drb/invoke'

module DRb
  class Service
    def initialize(uri = 'drb://', front = nil, config = { })
      config = DEFAULT_PRIMARY_CONFIG.merge(DEFAULT_CONFIG).merge(config)

      @server = ProtocolMgr.open_server(uri, front, config)
      DRb.register_server(@server) unless @server.nil?

      @grp = ThreadGroup.new
      @thread = run
    end

    def connect_to(uri)
      ObjectProxy.new(ProtocolMgr.open_client(@server, uri))
    end

    attr_reader :thread

    # overrides the assumed defaults defined in DEFAULT_PRIMARY_CONFIG
    DEFAULT_CONFIG = Hash.new

    private

    INSECURE_METHOD = [ :__send__ ]

    DEFAULT_PRIMARY_CONFIG = {
        :idconv => IdConverter,
        :argc_limit => 256,
        :load_limit => 256 * 1024 * 100,
        :verbose => false,
        :debug => false,
        :acl => nil # TODO are we still going to use ACLs?
    }

    def check_insecure_method(obj, msg_id)
      return true if obj.is_a?(Proc) && msg_id == :__drb_yield
      raise(ArgumentError, "#{any_to_s(msg_id)} is not a symbol") unless msg_id.is_a?(Symbol)
      raise(SecurityError, "insecure method `#{msg_id}`") if INSECURE_METHOD.include?(msg_id)

      if obj.private_methods.include?(msg_id)
        desc = any_to_s(obj)
        raise NoMethodError, "private method `#{msg_id}` called for #{desc}"
      elsif obj.protected_methods.include?(msg_id)
        desc = any_to_s(obj)
        raise NoMethodError, "protected method `#{msg_id}` called for #{desc}"
      else
        true
      end
    end

    def run
      Thread.start do
        begin
          loop do
            main_loop
          end
        ensure
          unless @server.nil?
            @server.close
            DRb.unregister_server @server
          end
        end
      end
    end

    def main_loop
      Thread.start(@server.accept) do |conn|
        @grp.add Thread.current

        loop do
          begin
            # I'm not sure if the InvokeMethod class is the best way of going about this
            # It has the recv_request in the class and leaves the send_reply outside of it...
            invoke_method = InvokeMethod.new(@server, *conn.recv_request)
            check_insecure_method *invoke_method.method_name
            succ, result = invoke_method.perform

            if !succ && @server.config[:verbose]
              p result
              result.backtrace.each do |x|
                puts x
              end
            end

            begin
              conn.send_reply(succ, result)
            rescue
              @server.log("!!!!!error: #{$!.message}")
              nil
            end
          ensure
            # TODO stop_service???
            unless succ
              conn.close
              break
            end
          end
        end
      end
    end
  end
end
