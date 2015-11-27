
module Dirby
  # Acts as an array of hash index to a remote object
  class QueryRef
    def initialize(query)
      @query = query
    end

    def to_s
      @query.to_s
    end
  end
end
