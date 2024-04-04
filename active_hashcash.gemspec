require_relative "lib/active_hashcash/version"

Gem::Specification.new do |spec|
  spec.name          = "active_hashcash"
  spec.version       = ActiveHashcash::VERSION
  spec.authors       = ["Alexis Bernard"]
  spec.email         = ["alexis@basesecrete.com"]
  spec.homepage      = "https://github.com/BaseSecrete/active_hashcash"
  spec.summary       = "Protect Rails applications against bots and brute force attacks without annoying humans."
  spec.description   = "Protect Rails applications against bots and brute force attacks without annoying humans."
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BaseSecrete/active_hashcash"
  spec.metadata["changelog_uri"] = "https://github.com/BaseSecrete/active_hashcash/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "*.txt", "*.md"]

  spec.required_ruby_version = ">= 2.4.0"
  spec.add_dependency "rails", ">= 5.2.0"
end
