# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "ecology/version"

Gem::Specification.new do |s|
  s.name        = "ecology"
  s.version     = Ecology::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Noah Gibbs"]
  s.email       = ["noah@ooyala.com"]
  s.homepage    = "http://www.ooyala.com"
  s.summary     = %q{Ruby config variable management}
  s.description = <<EOS
Ecology sets configuration data for an application based
on environment variables and other factors.  It is meant
to unify configuration data for logging, testing, monitoring
and deployment.
EOS

  s.rubyforge_project = "ecology"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "multi_json"

  s.add_development_dependency "bundler", "~> 1.0.10"
  s.add_development_dependency "scope", "~> 0.2.1"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
end
