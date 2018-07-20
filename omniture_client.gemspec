# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniture_client/version'

Gem::Specification.new do |spec|
  spec.name          = "omniture_client"
  spec.version       = OmnitureClient::VERSION
  spec.authors       = ["Sascha Knobloch"]
  spec.email         = ["saschaknobloch.dev@gmail.com"]
  spec.summary       = "Use Omniture's REST API with ease."
  spec.description   = "A library that allows access to Omniture's REST API libraries (developer.omniture.com)"
  spec.homepage      = "http://github.com/saschaknobloch/omniture_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"

  spec.add_runtime_dependency("httparty")
  spec.add_runtime_dependency("json")
  spec.add_runtime_dependency("logger")
end
