# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require './lib/dizby/version'

Gem::Specification.new do |spec|
  spec.name          = 'dizby'
  spec.version       = Dizby::VERSION
  spec.authors       = ['Nathan Currier']
  spec.email         = ['nathan.currier@gmail.com']
  spec.license       = 'MPL-2.0'

  spec.description   = 'Distributed Ruby'
  spec.summary       = 'Distributed Ruby'
  spec.homepage      = 'https://github.com/rideliner/dizby'
  spec.has_rdoc      = 'yard'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'net-ssh', '~> 4.0.beta'
  spec.add_runtime_dependency 'poly_delegate'

  spec.add_development_dependency 'rideliner'
  spec.add_development_dependency 'yard_rideliner'
  spec.add_development_dependency 'yard_dizby'

  spec.add_runtime_dependency 'rbnacl', '~> 3.4.0'
  spec.add_runtime_dependency 'rbnacl-libsodium', '~> 1.0.10'
  spec.add_runtime_dependency 'bcrypt_pbkdf', '~> 1.0.0.alpha1'
end
