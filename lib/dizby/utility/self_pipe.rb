# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  SelfPipe =
    Struct.new(:read, :write) do
      def close_read
        read.close if read && !read.closed?
      end

      def close_write
        write.close if write && !write.closed?
      end
    end
end
