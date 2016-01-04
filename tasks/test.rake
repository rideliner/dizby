# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = ['test/test_helper.rb']
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

namespace :test do
  desc 'Generate a test coverage report'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    task(:test).invoke
  end
end

CLOBBER.include 'coverage'
