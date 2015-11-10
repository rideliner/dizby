
require 'dirby/error'

module Dirby
  class ProtocolMgr
    # TODO all required portions of a Protocol class need to be documented
    def self.add_protocol(klass)
      @protocols << klass
    end

    def self.open_client(server, uri)
      klass, args = get_protocol(uri)
      supported_or_die(klass, :open_client)
      klass.open_client(server, *args)
    end

    def self.open_server(uri, front, config)
      klass, args = get_protocol(uri)
      supported_or_die(klass, :open_server)
      klass.open_server(front, config, *args)
    end

    def self.spawn_server(uri, command, config)
      klass, args = get_protocol(uri)
      supported_or_die(klass, :spawn_server)
      klass.spawn_server(command, config, *args)
    end

    private

    def self.get_protocol(uri)
      klass = @protocols.find { |klass| klass.regex =~ uri }

      if klass.nil?
        raise BadScheme, uri if @protocols.none? { |k| uri.start_with? "#{k.scheme}:" }
        raise BadURI, "can't parse uri: #{uri}"
      end

      [ klass, $~[1..-1] ]
    end

    def self.supported_or_die(klass, method)
      raise NotImplementedError, "#{method} not supported for #{klass}" unless klass.respond_to?(method)
    end

    @protocols = [ ]
  end
end