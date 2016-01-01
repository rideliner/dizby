# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  module UndumpableObject
    def _dump(_)
      fail TypeError, 'can\'t dump'
    end
  end
end
