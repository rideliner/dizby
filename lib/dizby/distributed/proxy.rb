# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'dizby/distributed/unknown'

module Dizby
  class ObjectProxy
    def initialize(conn, ref = nil)
      @ref = ref
      @conn = conn
    end

    def method_missing(msg_id, *args, &block)
      @conn.server.log.debug("calling through proxy: #{msg_id} #{args}")
      @conn.send_request(@ref, msg_id, *args, &block)
      succ, result = @conn.recv_reply

      return result if succ
      fail result if result.is_a?(UnknownObject)

      bt = Dizby.proxy_backtrace(@conn.remote_uri, result)
      result.set_backtrace(bt + caller)
      fail result
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      method_missing(:respond_to?, msg_id, priv)
    end
  end

  def self.proxy_backtrace(prefix, exception)
    bt = exception.backtrace.reject { |trace| /`__send__'$/ =~ trace }
    bt.map { |trace| %r{\(drb://} =~ trace ? trace : "#{prefix}#{trace}" }
    # TODO: why do we only add the prefix if the trace doesn't start with drb?
    # What about the other schemes?
  end
end
