
require 'dirby/distributed/semi_proxy'

module Dirby
  module ReadableStream
    def read
      sz = check_packet_size(load_size)
      str = load_packet(sz)

      raise ConnectionError, 'connection closed' unless str

      if str.size < sz
        raise ConnectionError, 'premature marshal format(can\'t read)'
      end

      load_obj(str)

      # TODO: un-tainting???
    end

    private

    def load_size
      @stream.read(4)
    rescue
      raise ConnectionError, $!.message, $!.backtrace
    end

    def load_packet(sz)
      @stream.read(sz)
    rescue
      raise ConnectionError, $!.message, $!.backtrace
    end

    def load_obj(marshalled_str)
      @server.log.debug("loading data: #{marshalled_str.inspect}")
      obj = Marshal.load(marshalled_str)
      @server.log.debug("loaded: #{obj.inspect}")

      # get a local object or create the proxy using the current server
      # done here since marshalling doesn't know about the current server
      obj = obj.evaluate(@server) if obj.is_a?(SemiObjectProxy)

      obj
    rescue NameError, ArgumentError
      @server.log.debug("unknown: #{$!.inspect} #{$!.backtrace}")
      UnknownObject.new($!, marshalled_str)
    end

    def check_packet_size(sz)
      raise RemoteServerShutdown unless sz
      raise ConnectionError, 'premature header' if sz.size < 4

      sz = sz.unpack('N')[0]

      # load_limit must be greater than the size of the packet
      # or the load_limit can be 0 or less to be considered "infinite"
      if @server.load_limit.between?(0, sz)
        raise ConnectionError, "too large packet for #{sz}"
      end

      sz
    end
  end
end
