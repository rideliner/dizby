
require 'dizby/error'

module Dizby
  class ProtocolManager
    # TODO: all required portions of a Protocol class need to be documented
    class << self
      def add_protocol(klass)
        @protocols << klass
      end

      def open_client(server, uri)
        call_refined(uri, :client, server)
      end

      def open_server(uri, front, config)
        call_refined(uri, :server, front, config)
      end

      def spawn_server(server, command, uri)
        call_refined(uri, :spawn, server, command)
      end

      private

      def call_refined(uri, refiner, *base_args)
        klass = get_protocol(uri)
        refined = refine_protocol(klass, refiner)
        args = get_arguments(refined, uri)
        refined.call(*base_args, args)
      end

      def get_protocol(uri)
        scheme = '' if uri.empty?
        scheme ||= uri.split(':').first
        fail BadScheme, "can't retrieve scheme: #{uri}" unless scheme

        protocol = @protocols.find { |klass| klass.scheme == scheme }
        protocol || fail(BadScheme, "scheme not found: #{scheme}")
      end

      def refine_protocol(protocol, refinement)
        refined = protocol.get_refinement(refinement)

        unless refined
          fail NotImplementedError,
               "#{refinement} refinement not supported for #{protocol}"
        end

        refined
      end

      def get_arguments(refined, uri)
        fail BadURI, "can't parse uri: #{uri}" unless refined.regex =~ uri

        $~[1..-1]
      end
    end

    @protocols = []
  end
end