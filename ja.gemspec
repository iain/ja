lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ja/version"

Gem::Specification.new do |spec|
  spec.name          = "ja"
  spec.version       = Ja::VERSION
  spec.authors       = ["iain"]
  spec.email         = ["iain@iain.nl"]
  spec.summary       = "Opinionated helpers for making JSON calls with the http.rb gem"
  spec.description   = "Opinionated helpers for making JSON calls with the http.rb gem"
  spec.homepage      = "https://github.com/iain/ja"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "rake", "~> 12"
  spec.add_development_dependency "rspec", "~> 3"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "semantic_logger"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "webmock"

  spec.add_dependency "http", ">= 3"
end
