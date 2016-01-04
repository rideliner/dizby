# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# require 'yard' TODO
require 'yard/rake/yardoc_task'

YARD::Rake::YardocTask.new(:yard)

CLEAN.include '.yardoc'
CLOBBER.include '_yardoc'
