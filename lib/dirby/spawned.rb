
# require the whole package, minimizes command length
require 'dirby'
require 'dirby/utility/io_barrier'

module Dirby
  def self.handle_spawned(uri, &block)
    service = nil

    barriers = [ $stdout, $stdin, $stderr ].map { |io| IOBarrier.new(io) }

    barriers.each &:block
    obj = block.call
    barriers.each &:allow

    obj.define_singleton_method :__dirby_exit__ do
      service.close unless service.nil?
    end

    service = Service.new(uri, obj)

    $stdout.puts "Running on port #{service.server.port}"

    service.wait
  end
end
