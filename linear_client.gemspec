# frozen_string_literal: true

require_relative "lib/linear_client/version"

Gem::Specification.new do |spec|
  spec.name        = "linear_client"
  spec.version     = LinearClient::VERSION
  spec.authors     = ["Lenio Ferretto"]
  spec.email       = ["ferretto@users.noreply.github.com"]

  spec.summary     = "Cliente Ruby puro para a API GraphQL do Linear"
  spec.description = "Cliente minimalista, sem dependencias externas, para criar issues, " \
                      "comentar e consultar dados no Linear (linear.app) via sua API GraphQL."
  spec.homepage    = "https://github.com/ferretto/linear_client"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|\.github)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.26"
end
