# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'bundler/gem_tasks'

CLEAN.include '.yardoc'
CLOBBER.include '_yardoc', 'coverage'

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new(:yard)

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.fail_on_error = false
end
task('rubocop:auto_correct').clear

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

task default: %i(rubocop test)
