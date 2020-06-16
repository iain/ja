# frozen_string_literal: true

require_relative "lib/ja/version"

Gem::Specification.new do |spec|

  spec.name          = "ja"
  spec.version       = Ja::VERSION
  spec.authors       = ["iain"]
  spec.email         = ["iain@iain.nl"]

  spec.summary       = "Opinionated helpers for making JSON calls with the http.rb gem"
  spec.description   = "Opinionated helpers for making JSON calls with the http.rb gem"
  spec.homepage      = "https://github.com/iain/ja"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "https://github.com/iain/ja/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "semantic_logger"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "webmock"

  spec.add_dependency "http", ">= 4.0.0"
end
