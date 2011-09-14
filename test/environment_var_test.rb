require File.join(File.dirname(__FILE__), "test_helper.rb")

class EnvironmentTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with environments in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "environment-from": ["RACK_ENV"]
}
ECOLOGY_CONTENTS
    end

    should "default to development" do
      Ecology.read
      assert_equal "development", Ecology.environment
    end

  end
end
