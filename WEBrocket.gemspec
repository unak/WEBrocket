# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'webrocket/version'

Gem::Specification.new do |spec|
  spec.name          = "WEBrocket"
  spec.version       = WEBrocket::VERSION
  spec.authors       = ["U.Nakamura"]
  spec.email         = ["usa@garbagecollect.jp"]
  spec.description   = %q{WebSocket extension for WEBrick}
  spec.summary       = %q{WebSocket extension for WEBrick}
  spec.homepage      = "https://github.com/unak/WEBRocket"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
end
