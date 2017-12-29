# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'h2o-configurator'
  spec.version       = '0.2'
  spec.authors       = ['John Labovitz']
  spec.email         = ['johnl@johnlabovitz.com']

  spec.summary       = %q{Build H2O config files.}
  spec.description   = %q{H2OConfigurator builds H2O config files.}
  spec.homepage      = %q{https://github.com/jslabovitz/h2o-configurator}
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'path'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
end