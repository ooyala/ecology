require File.join(File.dirname(__FILE__), "test_helper.rb")

class EnvironmentVarTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with environments in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "environment-from": ["RACK_ENV"],
  "domain": {
    "property1" : {
      "env:staging": "value1",
      "env:development": "value2",
      "env:*": "value3"
    }
  }
}
ECOLOGY_CONTENTS

      ENV["RACK_ENV"] = nil
    end

    #should "select the right environment value for a property" do
    #  ENV["RACK_ENV"] = "staging"
    #  Ecology.read
    #  assert_equal "value2", Ecology.property("domain::property1", :as => String)
    #end

  end
end
