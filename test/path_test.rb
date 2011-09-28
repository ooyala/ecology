require File.join(File.dirname(__FILE__), "test_helper.rb")

class PathTest < Scope::TestCase
  setup do
    Ecology.reset
  end

  context "with paths in your ecology" do
    setup do
      set_up_ecology <<ECOLOGY_CONTENTS
{
  "application": "SomeApp",
  "paths": {
    "pid_location": "/pid_dir/",
    "whozit_location": "$app/../dir1",
    "whatsit_path": "$cwd/logs",
    "some_other_location": "dir/to/there.$pid"
  }
}
ECOLOGY_CONTENTS
      Ecology.read
    end

    should "find an absolute path" do
      assert_equal "/pid_dir/", Ecology.path("pid_location")
    end

    should "find an application-relative path" do
      $0 = "some/path/my_app.rb"
      assert_equal "some/path/../dir1", Ecology.path("whozit_location")
    end

    should "find a cwd-relative path" do
      Dir.expects(:getwd).returns("some/path")
      assert_equal "some/path/logs", Ecology.path("whatsit_path")
    end

    should "substitute correctly for a PID path" do
      Process.expects(:pid).returns(379)
      assert_equal "dir/to/there.379", Ecology.path("some_other_location")
    end
  end

end
