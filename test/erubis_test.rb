require File.join(File.dirname(__FILE__), "test_helper.rb")
require "multi_json"

class ErubisTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with a .erb ecology" do
    setup do
      set_up_ecology(<<ECOLOGY_CONTENTS, "some_app.ecology.erb")
{
  "application": "SomeApp",
  "domain": {
    "property1" :
      <% if ENV["BOBO"] %>
        37
      <% else %>
        42
      <% end %>
  },
  "bobo": <%= MultiJson.encode(ENV["BOBO"]) %>
}
ECOLOGY_CONTENTS

      ENV["BOBO"] = nil
    end

    should "Parse conditionally with Erubis" do
      ENV["BOBO"] = "true"
      Ecology.read
      assert_equal 37, Ecology.property("domain::property1")
    end

    should "Parse conditionally with Erubis when a variable is unset" do
      Ecology.read
      assert_equal 42, Ecology.property("domain::property1")
    end

#    should "Return values from Erubis" do
#      ENV["BOBO"] = { "a" => "b", "c" => "d" }
#      Ecology.read
#      assert_equal { "a" => "b", "c" => "d" }, Ecology.property("bobo")
#    end
  end
end
