require File.join(File.dirname(__FILE__), "test_helper.rb")

class PropertyTest < Scope::TestCase
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
    "property1" : "strval1",
    "property2" : "374",
    "property3" : 1987
  }
}
ECOLOGY_CONTENTS
      Ecology.read
    end

    should "get a string property without a typecast" do
      assert_equal "strval1", Ecology.property("domain::property1")
    end

    should "get a string property with a typecast" do
      assert_equal "strval1", Ecology.property("domain::property1", :as => String)
    end

    should "get a string-number property with a String typecast" do
      assert_equal "374", Ecology.property("domain::property2", :as => String)
    end

    should "get a string-number property with a Fixnum typecast" do
      assert_equal 374, Ecology.property("domain::property2", :as => Fixnum)
    end

    should "get a string-number property with no typecast" do
      assert_equal "374", Ecology.property("domain::property2")
    end

    should "get an integer property with a String typecast" do
      assert_equal "1987", Ecology.property("domain::property3", :as => String)
    end

    should "get an integer property with a Fixnum typecast" do
      assert_equal 1987, Ecology.property("domain::property3", :as => Fixnum)
    end

    should "get an integer property with no typecast" do
      assert_equal 1987, Ecology.property("domain::property3")
    end
  end
end
