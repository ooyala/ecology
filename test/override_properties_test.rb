require File.join(File.dirname(__FILE__), "test_helper.rb")

class OverridePropertiesTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with environment-from in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_PARENT_CONTENTS, "parent.ecology"
{
  "logging": {
    "property1": "foo"
  },
  "monitoring": {
    "property2": "bar"
  }
}
ECOLOGY_PARENT_CONTENTS

      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "uses": "parent.ecology",
  "monitoring": {
    "property2": "baz"
  }
}
ECOLOGY_CONTENTS
    end

    should "get overridden properties correctly" do
      Ecology.read
      assert_equal "baz", Ecology.property("monitoring::property2")
    end

    should "get inherited properties correctly" do
      Ecology.read
      assert_equal "foo", Ecology.property("logging::property1")
    end
  end
end
