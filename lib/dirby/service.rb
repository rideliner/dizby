
require 'dirby/registration'
require 'dirby/manager'
require 'dirby/proxy'
require 'dirby/converter'
require 'dirby/error'
require 'dirby/invoke'
require 'dirby/util'

module Dirby
  class Service
    def initialize(uri = '', front = nil, config = { })
      config = DEFAULT_PRIMARY_CONFIG.merge(DEFAULT_CONFIG).merge(config)

      @server = ProtocolMgr.open_server(uri, front, config)
    rescue NonAcceptingServer => e
      # This is to allow servers that don't accept connections
      # Not all servers will allow connections back to them, so don't allow it. Period.
      # TODO if a client requests a backwards connection, do they get an error???
      @server = e.server
      @server.log('using a server that does not allow connections') unless @server.nil?
    else
      @grp = ThreadGroup.new
      @thread = run
    ensure
      Dirby.register_server(@server) unless @server.nil?
    end

    def connect_to(uri)
      ObjectProxy.new(ProtocolMgr.open_client(@server, uri))
    end

    # overrides the assumed defaults defined in DEFAULT_PRIMARY_CONFIG
    DEFAULT_CONFIG = Hash.new

    def close
      unless @server.nil?
        Dirby.unregister_server @server
        @server.shutdown
      end
    end

    def alive?
      !@server.nil? && @server.alive?
    end

    def wait
      @thread.join unless @thread.nil?
    end

    private

    INSECURE_METHOD = [ :__send__ ]

    DEFAULT_PRIMARY_CONFIG = {
        :idconv => IdConverter,
        :argc_limit => 256,
        :load_limit => 256 * 1024 * 100,
        :verbose => false,
        :debug => false,
        :tcp_acl => nil
    }

    def check_insecure_method(obj, msg_id)
      return true if obj.is_a?(Proc) && msg_id == :__drb_yield # TODO what is with __drb_yield?!? remnant of DRb
      raise ArgumentError, "#{Dirby.any_to_s(msg_id)} is not a symbol" unless msg_id.is_a?(Symbol)
      raise SecurityError, "insecure method `#{msg_id}`" if INSECURE_METHOD.include?(msg_id)

      if obj.private_methods.include?(msg_id)
        desc = Dirby.any_to_s(obj)
        raise NoMethodError, "private method `#{msg_id}` called for #{desc}"
      elsif obj.protected_methods.include?(msg_id)
        desc = Dirby.any_to_s(obj)
        raise NoMethodError, "protected method `#{msg_id}` called for #{desc}"
      else
        true
      end
    end

    def run
      Thread.start do
        begin
          loop do
            @grp.add(main_loop)
          end
        rescue ServerShutdown
          @server.log('Server shutdown')
        ensure
          unless alive?
            @server.close
          end

          unless @grp.nil?
            @grp.enclose
            threads = @grp.list.delete_if(&:nil?)

            # TODO test this
            threads.each { |t| t[:dirby][:client].close }
            threads.each(&:join)
          end

          @server = nil
          @grp = nil
        end
      end
    end

    def main_loop
      conn0 = @server.accept
      return nil if conn0.nil?

      Thread.start(conn0) do |conn|
        Thread.current[:dirby] = {
            :client => conn,
            :service => self,
            :server => @server
        } # TODO Is this really necessary?
        # client gets used when closing the server, the others aren't used at the moment.

        @server.add_uri_alias conn.remote_uri

        process_requests(conn)
      end
    end

    def process_requests(conn)
      verbose = @server.verbose

      begin
        # I'm not sure if the InvokeMethod class is the best way of going about this
        # It has the recv_request in the class and leaves the send_reply outside of it...
        invoke_method = InvokeMethod.new(@server, *conn.recv_request)
        check_insecure_method *invoke_method.method_name
        succ, result = invoke_method.perform

        if !succ && verbose
          p result
          result.backtrace.each do |x|
            puts x
          end
        end

        begin
          conn.send_reply(succ, result)
        rescue
          @server.log("!!!!!error#{$/}#{$!.message}#{$/ * 2}    #{$!.backtrace}#{$/}!!!!!end error")
          nil # TODO this isn't getting used, why is it here?
        end
      rescue ServerShutdown
        @server.log("server shutdown, closed connection to #{conn.remote_uri}") # TODO more info
        succ = false
      rescue RemoteShutdown
        @server.log("remote connection closed to #{conn.remote_uri}")
        succ = false
      ensure
        conn.close unless succ
      end while succ
    end
  end
end