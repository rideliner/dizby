
require 'drb/manager'

module DRb
  class BasicServer
    def initialize(uri, front, config)
      @config = config
      @uri = uri
      @front = front

      @argc_limit = @config[:argc_limit]
      @load_limit = @config[:load_limit]
      @idconv = @config[:idconv]
      @acl = @config[:acl]
    end

    def close
      raise NotImplementedError
    end

    def accept
      raise NotImplementedError
    end

    def connect_to(uri)
      ProtocolMgr.open_client(self, uri)
    end

    def to_obj(ref)
      return @front if ref.nil?
      @idconv.to_obj(ref)
    end

    def to_id(obj)
      return nil if obj.__id__ == @front.__id__
      @idconv.to_id(obj)
    end

    attr_reader :argc_limit, :load_limit
    attr_reader :uri, :front
    attr_reader :config

    def log(msg)
      if @config[:debug]
        msg_ = "#{@uri} : #{msg}"
        if @config[:debug].is_a?(IO)
          @config[:debug] << msg_
        else
          puts msg_
        end
      end
    end
  end
end
