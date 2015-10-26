#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'drb'

class Foo
  include DRb::UndumpableObject

  def initialize(t)
    @t = t
  end

  def to_a
    @t.to_a
  end
end

class TimeServer
  def getCurrentTime
    Time.now
  end

  def oldTime=(t)
    @time = t
  end

  def oldTime
    @time.to_a
  end
end

if ARGV.length > 0
  case ARGV[0]
    when 'client'
    if ARGV.length == 3
      hostname = ARGV[1]
      port = (4000 + 1000 * ARGV[2].to_i).to_s
    else
      abort 'Specify a hostname and client number'
    end
    front = nil
  when 'server'
    port = '4000'
    front = TimeServer.new
  end
else
  abort 'Specify client/server'
end

config = { :verbose => true, :debug => false }
service = DRb::Service.new "drb://:#{port}", front, config

if ARGV[0] == 'client'
  proxy = service.connect_to("drb://#{hostname}:4000")
  #puts proxy.getCurrentTime
  proxy.oldTime = Foo.new([:a, 12, 'hello'])
  p proxy.oldTime
elsif ARGV[0] == 'server'
  service.thread.join
end