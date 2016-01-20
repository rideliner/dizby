# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  PROTOCOL_REGEX = {
    user: '(?:(.+?)@)',
    host: '(.*?)',
    port: '(?::(\d+))',
    file: '(.+?)',
    query: '(?:\?(.*?))'
  }.freeze

  class RefinedProtocol
    def initialize(regex, &block)
      @regex = /^#{format(regex, Dizby::PROTOCOL_REGEX)}$/
      @block = block
    end

    attr_reader :regex

    def call(*args)
      @block.call(*args)
    end
  end
end
