# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require 'force_bind' if RUBY_ENGINE == 'ruby'

module Dizby
  # rubocop:disable Lint/DuplicateMethods
  case RUBY_ENGINE
  when 'rbx'
    def self.force_bind(bound_obj, method)
      method_args = [method.defined_in, method.executable, method.name]

      Method.new(bound_obj, *method_args)
    end
  when 'ruby'
    def self.force_bind(bound_obj, method)
      method.force_bind(bound_obj)
    end
  else
    fail "force binding is not supported on #{RUBY_ENGINE}"
  end
  # rubocop:enable Lint/DuplicateMethods
end
