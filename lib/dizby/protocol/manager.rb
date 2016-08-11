# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
        raise BadScheme, "can't retrieve scheme: #{uri}" unless scheme

        protocol = @protocols.find { |klass| klass.scheme == scheme }
        protocol || raise(BadScheme, "scheme not found: #{scheme}")
      end

      def refine_protocol(protocol, refinement)
        refined = protocol.get_refinement(refinement)
        return refined if refined

        raise NotImplementedError,
              "#{refinement} refinement not supported for #{protocol}"
      end

      def get_arguments(refined, uri)
        raise BadURI, "can't parse uri: #{uri}" unless refined.regex =~ uri

        $~[1..-1]
      end
    end

    @protocols = []
  end
end
