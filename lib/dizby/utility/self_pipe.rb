# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  SelfPipe =
    Struct.new(:read, :write) do
      def close_read
        read.close unless read_closed?
      end

      def read_closed?
        !read || read.closed?
      end

      def close_write
        write.close unless write_closed?
      end

      def write_closed?
        !write || write.closed?
      end
    end
end
