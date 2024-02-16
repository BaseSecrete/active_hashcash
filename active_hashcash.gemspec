# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_hashcash/version"

Gem::Specification.new do |spec|
  spec.name          = "active_hashcash"
  spec.version       = ActiveHashcash::VERSION
  spec.authors       = ["Alexis Bernard"]
  spec.email         = ["alexis@basesecrete.com"]

  spec.summary       = "ActiveHashcash protects your Rails application against brute force attacks, DoS and bots."
  spec.description   = "ActiveHashcash protects your Rails application against brute force attacks, DoS and bots."
  spec.homepage      = "https://github.com/BaseSecrete/active_hashcash"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BaseSecrete/active_hashcash"
  spec.metadata["changelog_uri"] = "https://github.com/BaseSecrete/active_hashcash/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z lib LICENSE.txt README.md CHANGELOG.md`.split("\x0")
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 5.2.0"
end
