# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/quick_debounce/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-quick-debounce'
  spec.version       = Sidekiq::QuickDebounce::VERSION
  spec.authors       = ['Tom Johnell']
  spec.email         = ['tjohnell@gmail.com']
  spec.summary       = 'A client-side middleware for quickly debouncing Sidekiq jobs'
  spec.description   = <<-TXT
TBD
TXT
  spec.homepage      = 'https://github.com/tldev/sidekiq-quick-debounce'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq', '>= 2.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'mock_redis'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.0'
  spec.add_development_dependency 'minitest'
end
