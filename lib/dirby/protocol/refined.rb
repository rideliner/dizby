
module Dirby
  PROTOCOL_REGEX = {
    user: '(?:(.+?)@)',
    host: '(.*?)',
    port: '(?::(\d+))',
    file: '(.+?)',
    query: '(?:\?(.*?))'
  }

  class RefinedProtocol
    def initialize(regex, &block)
      @regex = /^#{format(regex, Dirby::PROTOCOL_REGEX)}$/
      @block = block
    end

    attr_reader :regex

    def call(*args)
      @block.call(*args)
    end
  end
end
