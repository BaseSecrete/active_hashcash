# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "active_hashcash"
  spec.version       = "0.1.0"
  spec.authors       = ["Alexis Bernard"]
  spec.email         = ["alexis@basesecrete.com"]

  spec.summary       = "Potect your rails application against DoS and bots."
  spec.description   = "It blocks bots that do not interpret JavaScript since the proof of work is not computed. For the more sophisticated bots, we are happy to slow them down."
  spec.homepage      = "https://github.com/BaseSecrete/active_hashcash"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'https://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BaseSecrete/active_hashcash"
  spec.metadata["changelog_uri"] = "https://github.com/BaseSecrete/active_hashcash/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport", ">= 5.2.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
