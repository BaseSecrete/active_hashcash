# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "active_hashcash"
  spec.version       = "0.1.0"
  spec.authors       = ["Alexis Bernard"]
  spec.email         = ["alexis@basesecrete.com"]

  spec.summary       = "Potect your Rails application against DoS and bots."
  spec.description   = "Potect your Rails application against DoS and bots."
  spec.homepage      = "https://github.com/BaseSecrete/active_hashcash"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BaseSecrete/active_hashcash"
  spec.metadata["changelog_uri"] = "https://github.com/BaseSecrete/active_hashcash/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.2.0"
  spec.add_dependency "actionview", ">= 5.2.0"
  spec.add_dependency "railties", ">= 5.2.0"
end
