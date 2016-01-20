# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

require './lib/dizby/version'

Gem::Specification.new do |spec|
  spec.name          = 'dizby'
  spec.version       = Dizby::VERSION
  spec.authors       = ['Nathan Currier']
  spec.email         = ['nathan.currier@gmail.com']
  spec.license       = 'BSD-3-Clause'

  spec.description   = 'Distributed Ruby'
  spec.summary       = 'Distributed Ruby'
  spec.homepage      = 'https://github.com/rideliner/dizby'
  spec.has_rdoc      = 'yard'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'net-ssh'

  spec.add_dependency 'bundler', '>= 1.11.2'

  spec.add_development_dependency 'rubocop', '>= 0.36.0'
  spec.add_development_dependency 'yard-dizby'
  spec.add_development_dependency 'kramdown'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codecov'
end
