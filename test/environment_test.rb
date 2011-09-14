require File.join(File.dirname(__FILE__), "test_helper.rb")

class EnvironmentTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with environment-from in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "environment-from": ["SOME_ENV_VAR", "VAR2"]
}
ECOLOGY_CONTENTS

      ENV["SOME_ENV_VAR"] = ENV["VAR2"] = nil
    end

    should "default to the development environment" do
      Ecology.read
      assert_equal "development", Ecology.environment
    end

    should "use the environment variables to determine environment" do
      ENV["SOME_ENV_VAR"] = "staging"
      Ecology.read
      assert_equal "staging", Ecology.environment
    end

    should "use secondary environment variables when the primary isn't set" do
      ENV["VAR2"] = "daily-staging"
      Ecology.read
      assert_equal "daily-staging", Ecology.environment
    end

    should "use primary environment variables in preference to secondary" do
      ENV["SOME_ENV_VAR"] = "theatrical staging"
      ENV["VAR2"] = "daily-staging"
      Ecology.read
      assert_equal "theatrical staging", Ecology.environment
    end
  end

  context "with an environment override in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "environment": "not really staging",
  "environment-from": "SOME_ENV_VAR"
}
ECOLOGY_CONTENTS
    end

    should "use the environment override" do
      Ecology.read
      assert_equal "not really staging", Ecology.environment
    end
  end

  context "with a single environment-from in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "environment-from": "SOME_ENV_VAR"
}
ECOLOGY_CONTENTS
    end

    should "use the environment override" do
      ENV['SOME_ENV_VAR'] = "bob's pants"
      Ecology.read
      assert_equal "bob's pants", Ecology.environment
    end
  end
end
