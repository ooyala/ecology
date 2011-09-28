require File.join(File.dirname(__FILE__), "test_helper.rb")

class EnvironmentTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "without an ecology" do
    should "call on_initialize events at initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.on_initialize { callee_mock.method }
      Ecology.read
    end

    should "call on_initialize events when called after initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.read
      Ecology.on_initialize { callee_mock.method }
    end
  end

  context "with an ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp"
}
ECOLOGY_CONTENTS
    end

    should "call on_initialize events at initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.on_initialize { callee_mock.method }
      Ecology.read
    end

    should "call on_initialize events when called after initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.read
      Ecology.on_initialize { callee_mock.method }
    end
  end

end
