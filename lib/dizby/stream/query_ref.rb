# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
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
