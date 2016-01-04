# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.fail_on_error = false
end

task('rubocop:auto_correct').clear
