require File.join(File.dirname(__FILE__), "test_helper.rb")

class EnvironmentTest < Scope::TestCase
  setup do
    Ecology.remove_trigger("test_on_init")
    Ecology.remove_trigger("test_on_reset")
    Ecology.reset
  end

  context "without an ecology" do
    should "call on_initialize events at initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.on_initialize("test_on_init") { callee_mock.method }
      Ecology.read
    end

    should "call on_initialize events when called after initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.read
      Ecology.on_initialize("test_on_init") { callee_mock.method }
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

      Ecology.on_initialize("test_on_init") { callee_mock.method }
      Ecology.read
    end

    should "call on_initialize events when called after initialize" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method)

      Ecology.read
      Ecology.on_initialize("test_on_init") { callee_mock.method }
    end

    should "call on_initialize events again after reset" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method).twice

      Ecology.on_initialize("test_on_init") { callee_mock.method }
      Ecology.read
      Ecology.reset
      Ecology.read
    end

    should "call on_reset events across multiple resets" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method).twice

      Ecology.read
      Ecology.on_reset("test_on_reset") { callee_mock.method }
      Ecology.reset
      Ecology.reset
    end

    should "remove on_reset events after remove_trigger" do
      callee_mock = mock("object that gets called")
      callee_mock.expects(:method).once  # Not three times...

      Ecology.read
      Ecology.on_reset("on_reset_remove") { callee_mock.method }
      Ecology.reset
      Ecology.remove_trigger("on_reset_remove")
      Ecology.reset
      Ecology.reset
    end
  end

end
