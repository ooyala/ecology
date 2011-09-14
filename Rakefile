require "bundler"
require "rake/testtask"

require File.join(File.dirname(__FILE__), "lib", "ecology", "version")

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir.glob("test/**/*test.rb")
  t.verbose = true
end

desc 'Builds the gem'
task :build do
  sh "gem build ecology.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install ecology-#{Ecology::VERSION}"
end
