require "rubygems"
require "bundler"
Bundler.require(:default, :development)
require "minitest/autorun"

# For testing Ecology itself, use the local version *first*.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "ecology"

class Scope::TestCase
  def set_up_ecology(file_contents, filename = "some.ecology")
    match = filename.match(/^(.*)\.erb$/)
    if match
      ENV["ECOLOGY_SPEC"] = match[1]
      File.stubs(:exist?).with(match[1]).returns(false)
    else
      ENV["ECOLOGY_SPEC"] = filename
    end

    File.stubs(:exist?).with(filename + ".erb").returns(false)
    File.stubs(:exist?).with(filename).returns(true)
    File.expects(:read).with(filename).returns(file_contents).at_least_once
  end

end
