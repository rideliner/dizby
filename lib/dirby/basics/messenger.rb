
module Dirby
  class Messenger
    def initialize(server, stream)
      @server = server
      @stream = stream
    end

    attr_reader :server, :remote_uri

    def close
      if @stream
        @stream.close
        @stream = nil
      end
    end

    protected

    def load_data(load_limit = -1)
      begin
        sz = @stream.read(4)
      rescue
        raise ConnectionError, $!.message, $!.backtrace
      end

      raise RemoteShutdown, 'connection closed' if sz.nil?
      raise ConnectionError, 'premature header' if sz.size < 4
      sz = sz.unpack('N')[0]
      raise ConnectionError, "too large packet for #{sz}" if load_limit < sz && load_limit > 0

      begin
        str = @stream.read(sz)
      rescue
        raise ConnectionError, $!.message, $!.backtrace
      end

      raise ConnectionError, 'connection closed' if str.nil?
      raise ConnectionError, 'premature marshal format(can\'t read)' if str.size < sz

      load_obj(str)
    end

    def dump_data(obj, error = false)
      if obj.kind_of?(UndumpableObject)
        @server.log.debug("dumping undumpable: #{obj.inspect}")
        obj = @server.make_distributed(obj, error)
      else
        @server.log.debug("dumping: #{obj.inspect}")
      end

      begin
        str = Marshal::dump(obj)
        @server.log.debug("dumped: #{str.inspect}")
      rescue
        @server.log.debug('rescuing and dumping pseudo-undumpable...')
        str = Marshal::dump(@server.make_distributed(obj, error))
        @server.log.debug("dumped: #{str.inspect}")
      end

      [str.size].pack('N') + str
    end

    # stream needs to have the read(int), write(str), and close() methods
    # this value can be overloaded in the client and server classes for your protocol
    attr_reader :stream

    private

    def load_obj(marshalled_str)
      obj = nil

      begin
        @server.log.debug("loading data: #{marshalled_str.inspect}")
        obj = Marshal::load(marshalled_str)
        @server.log.debug("loaded: #{obj.inspect}")

        # get a local object or create the proxy using the current server
        # has to be done here since marshalling doesn't know about the current server
        obj = obj.evaluate(@server) if obj.is_a?(SemiObjectProxy)
      rescue NameError, ArgumentError
        @server.log.debug("unknown: #{$!.inspect} #{$!.backtrace}")
        obj = UnknownObject.new($!, marshalled_str)
        @server.log.debug("loaded unknown object: #{obj.inspect}")
      end

      obj
      # TODO something about un-tainting ??
    end
  end
end
