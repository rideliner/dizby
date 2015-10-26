
module DRb
  module UndumpableObject
    def _dump(_)
      raise TypeError, 'can\'t dump'
    end
  end
end