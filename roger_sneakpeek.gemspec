# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/roger_sneakpeek/version"

Gem::Specification.new do |s|
  s.authors = ["Flurin Egger"]
  s.email = ["info@digitpaint.nl", "flurin@digitpaint.nl"]
  s.name = "roger_sneakpeek"
  s.version = RogerSneakpeek::VERSION
  s.homepage = "https://github.com/digitpaint/roger_sneakpeek"

  s.summary = "Deployment of releases to Sneakpeek server as Roger finalizer"
  s.description = <<-EOF
    Will upload the current release to the Sneakpeek server.
  EOF
  s.licenses = ["MIT"]

  s.date = Time.now.strftime("%Y-%m-%d")

  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "roger", "~> 1.7", ">= 1.0.0"
  s.add_dependency "faraday", "~> 0.8", ">= 0.8.11"

  s.add_development_dependency "rubocop", [">= 0"]
  s.add_development_dependency "rake", [">= 0"]
  s.add_development_dependency "test-unit", [">= 0"]
  s.add_development_dependency "thor", ["~> 0"]
  s.add_development_dependency "mocha", ["~> 1.1.0"]
end
