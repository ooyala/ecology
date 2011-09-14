require "rubygems"
require "bundler"
Bundler.require(:default, :development)
require "minitest/autorun"

# For testing Ecology itself, use the local version *first*.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "ecology"

class Scope::TestCase
  def set_up_ecology(file_contents, filename = "some.ecology")
    ENV["ECOLOGY_SPEC"] = filename
    File.expects(:exist?).with(filename).returns(true)
    File.expects(:read).with(filename).returns(file_contents)
  end

end
