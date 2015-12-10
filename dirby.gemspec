# coding: utf-8
require './lib/dirby/version'

Gem::Specification.new do |spec|
  spec.name          = 'dirby'
  spec.version       = Dirby::VERSION
  spec.authors       = ['Nathan Currier']
  spec.email         = ['nathan.currier@gmail.com']
  spec.license       = 'BSD-3-Clause'

  spec.description   = 'Distributed Ruby'
  spec.summary       = 'Distributed Ruby'
  spec.homepage      = 'https://gem.rideliner.net'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency 'net-ssh', '~> 3.0'

  spec.add_development_dependency 'rubocop', '~> 0.35'
  spec.add_development_dependency 'reek', '~> 3.7'
end
