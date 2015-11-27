
require 'dirby/error'

module Dirby
  class ProtocolMgr
    # TODO all required portions of a Protocol class need to be documented
    def self.add_protocol(klass)
      @protocols << klass
    end

    def self.open_client(server, uri)
      call_refined(uri, :client, server)
    end

    def self.open_server(uri, front, config)
      call_refined(uri, :server, front, config)
    end

    def self.spawn_server(server, command, uri)
      call_refined(uri, :spawn, server, command)
    end

    private

    def self.call_refined(uri, refiner, *base_args)
      klass = get_protocol(uri)
      refined = refine_protocol(klass, refiner)
      args = get_arguments(refined, uri)
      refined.call(*base_args, args)
    end

    def self.get_protocol(uri)
      scheme = uri.split(':').first
      raise BadScheme, "can't retrieve scheme: #{uri}" if scheme.nil?

      klass = @protocols.find { |klass| klass.scheme == scheme }
      klass || raise(BadScheme, "scheme not found: #{scheme}")
    end

    def self.refine_protocol(protocol, refinement)
      refined = protocol.get_refinement(refinement)
      refined || raise(NotImplementedError, "#{refinement} refinement not supported for #{protocol}")
    end

    def self.get_arguments(refined, uri)
      raise BadURI, "can't parse uri: #{uri}" unless refined.regex =~ uri

      $~[1..-1]
    end

    @protocols = [ ]
  end
end
