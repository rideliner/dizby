# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
