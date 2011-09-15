require File.join(File.dirname(__FILE__), "test_helper.rb")

class OverridePropertiesTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with environment-from in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_GRANDPARENT1_CONTENTS, "grandparent1.ecology"
{
  "testing": {
    "capabilities": [ "rails", "rvm" ],
    "othertag": 9
  },
  "monitoring": {
    "property9": 71
  }
}
ECOLOGY_GRANDPARENT1_CONTENTS

      set_up_ecology <<ECOLOGY_GRANDPARENT2_CONTENTS, "grandparent2.ecology"
{
  "monitoring": {
    "property3": 7,
    "property9": 134
  }
}
ECOLOGY_GRANDPARENT2_CONTENTS

      set_up_ecology <<ECOLOGY_PARENT_CONTENTS, "parent.ecology"
{
  "uses": ["grandparent1.ecology", "grandparent2.ecology"],
  "logging": {
    "property1": "foo"
  },
  "monitoring": {
    "property1": "burgers",
    "property2": "bar",
    "property3": "quux"
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
      Ecology.read
    end

    should "get overridden properties correctly" do
      assert_equal "baz", Ecology.property("monitoring::property2")
    end

    should "get inherited properties correctly" do
      assert_equal "foo", Ecology.property("logging::property1")
    end

    should "get properties in an overridden hash" do
      assert_equal "burgers", Ecology.property("monitoring::property1")
    end

    should "get grandparent properties" do
      assert_equal 9, Ecology.property("testing::othertag")
    end

    should "have first parent override second parent properties" do
      assert_equal 71, Ecology.property("monitoring::property9")
    end
  end
end
