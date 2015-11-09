
module DRb
  class SelfPipe < Struct.new(:read, :write)
    def close_read
      read.close unless read.nil? || read.closed?
    end

    def close_write
      write.close unless write.nil? || write.closed?
    end
  end
end
