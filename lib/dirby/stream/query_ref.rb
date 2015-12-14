
module Dirby
  # Acts as an array or hash index to a remote object
  class QueryRef
    def initialize(query)
      @query = query
    end

    def to_s
      @query.to_s
    end
  end
end
