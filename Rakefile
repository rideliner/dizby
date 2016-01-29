# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'bundler/gem_tasks'

Dir.glob('tasks/*.rake').each { |task| import task }

task default: %i(rubocop test)
task ci: 'test:coverage'
