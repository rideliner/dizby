# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/distributed/proxy'
require 'dizby/access/insecure'

module Dizby
  class DistributedObject
    def self._load(str)
      SemiObjectProxy.new(*Marshal.load(str))
    end

    def _dump(_)
      Marshal.dump [@server.uri, @server.to_id(@obj)]
    end

    def initialize(obj, server)
      @obj = obj
      @server = server
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      responds =
        case msg_id
        when :_dump
          true
        when :marshal_dump
          false
        else
          method_missing(:respond_to?, msg_id, priv)
        end

      @server.log.debug("respond_to?(#{msg_id}) => #{responds}")
      responds
    end

    def method_missing(msg_id, *args, &block)
      @server.log.debug("calling: #{msg_id} #{args.join ', '}")
      Dizby.check_insecure_method(@obj, msg_id)
      @obj.__send__(msg_id, *args, &block)
    end
  end
end
