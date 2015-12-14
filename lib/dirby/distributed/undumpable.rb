
module Dirby
  module UndumpableObject
    def _dump(_)
      fail TypeError, 'can\'t dump'
    end
  end
end
