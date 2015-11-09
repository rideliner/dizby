
require 'shellwords'

module DRb
  class SpawnCommand
    TEMPLATE = <<EOF
require 'drb'

obj = begin
%s
end

service = nil

obj.define_singleton_method :__drb_exit__ do
  service.close unless service.nil?
end

service = DRb::Service.new '%s', obj
service.thread.join
EOF

    def initialize(data)
      @data = data
      @ruby_cmd = 'ruby'
      @uri = 'drb://'
    end

    attr_accessor :ruby_cmd, :uri

    def to_cmd
      [ @ruby_cmd, '-e', TEMPLATE % [ @data, @uri ] ].shelljoin
    end
    alias_method :to_s, :to_cmd

    class << self
      def text(script)
        self.new(script)
      end

      def local_file(file)
        self.new File.read(file)
      end

      def remote_file(file, obj_name)
        self.new "load '#{file}'; #{obj_name}"
      end
    end
  end
end