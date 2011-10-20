module Ecology
  module Test
    def set_up_ecology(file_contents, filename = "some.ecology", options = {})
      match = filename.match(/^(.*)\.erb$/)
      if match
        ENV["ECOLOGY_SPEC"] = match[1]
        File.stubs(:exist?).with(match[1]).returns(false)
      else
        ENV["ECOLOGY_SPEC"] = filename
      end

      File.stubs(:exist?).with(filename + ".erb").returns(false)
      File.stubs(:exist?).with(filename).returns(true)

      unless options[:no_read]
        File.expects(:read).with(filename).returns(file_contents).at_least_once
      end
    end
  end
end
