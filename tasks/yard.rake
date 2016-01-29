# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'yard_dizby/rake_overload'

YARD::Rake::YardocTask.new(:yard)

CLEAN.include '.yardoc'
CLOBBER.include '_yardoc'
