# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/error'
require 'dizby/protocol/structs'

module Dizby
  class ProtocolManager
    # TODO: all required portions of a Protocol class need to be documented
    class << self
      def add_protocol(klass)
        @protocols << klass
      end

      def open_client(server, client_args)
        call_refined(:client, client_args, server)
      end

      def open_server(server_args)
        call_refined(:server, server_args)
      end

      def spawn_server(server, spawn_args)
        call_refined(:spawn, spawn_args, server)
      end

      private

      def call_refined(refiner, base_args, *bonus_args)
        klass = get_protocol(base_args.uri)
        refined = refine_protocol(klass, refiner)
        args = get_arguments(refined, base_args.uri)
        refined.call(base_args, *bonus_args, args)
      end

      def get_protocol(uri)
        scheme = '' if uri.empty?
        scheme ||= uri.split(':').first
        raise BadScheme, "can't retrieve scheme: #{uri}" unless scheme

        protocol = @protocols.find { |klass| klass.scheme == scheme }
        protocol || raise(BadScheme, "scheme not found: #{scheme}")
      end

      def refine_protocol(protocol, refinement)
        refined = protocol.refinements[refinement]
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
