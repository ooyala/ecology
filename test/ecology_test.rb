require File.join(File.dirname(__FILE__), "test_helper.rb")
require "thread"

class EcologyTest < Scope::TestCase
  context "with ecology" do
    setup do
      Ecology.reset
    end

    should "correctly determine default ecology names" do
      assert_equal "/path/to/bob.txt.ecology", Ecology.default_ecology_name("/path/to/bob.txt.rb")
      assert_equal "relative/path/to/app.ecology", Ecology.default_ecology_name("relative/path/to/app.rb")
      assert_equal "/path/to/bob.ecology", Ecology.default_ecology_name("/path/to/bob.sh")
      assert_equal "\\path\\to\\bob.ecology", Ecology.default_ecology_name("\\path\\to\\bob.EXE")
    end

    should "respect the ECOLOGY_SPEC environment variable" do
      ENV['ECOLOGY_SPEC'] = '/tmp/bobo.txt'
      File.expects(:exist?).with('/tmp/bobo.txt.erb').returns(false).at_least_once
      File.expects(:exist?).with('/tmp/bobo.txt').returns(true)
      File.expects(:read).with('/tmp/bobo.txt').returns('{ "application": "foo_app" }')
      Ecology.read

      assert_equal "foo_app", Ecology.application
    end

    should "recognize that this is the main thread" do
      assert_equal "main", Ecology.thread_id(Thread.current)
    end

    should "work without an ECOLOGY_SPEC" do
      $0 = "whatever_app.rb"

      ENV['ECOLOGY_SPEC'] = nil
      File.expects(:exist?).with("whatever_app.ecology.erb").returns(false).at_least_once
      File.expects(:exist?).with("whatever_app.ecology").returns(false)

      Ecology.read

      assert_equal "whatever_app.rb", Ecology.application
    end

    should "prevent repeat Ecology.read with different ecology files" do
      set_up_ecology <<JSON
{
  "application": "bob"
}
JSON
      Ecology.read
      set_up_ecology(<<JSON, "other.ecology", :no_read => true)
{
  "application": "sam"
}
JSON
      assert_raises(RuntimeError) do
        Ecology.read
      end
    end

    should "allow repeat Ecology.read with same ecology files" do
      set_up_ecology(<<JSON, "same.ecology")
{
  "application": "bob"
}
JSON
      Ecology.read
      set_up_ecology(<<JSON, "same.ecology", :no_read => true)
{
  "application": "sam"
}
JSON
      Ecology.read  # should not raise
    end

    should "allow repeat Ecology.read with different paths to the same ecology files" do
      set_up_ecology(<<JSON, "same.ecology")
{
  "application": "bob"
}
JSON
      Ecology.read
      set_up_ecology(<<JSON, "./same.ecology", :no_read => true)
{
  "application": "sam"
}
JSON
      Ecology.read  # should not raise
    end
  end
end
