require "multi_json"

module Ecology
  class << self
    attr_reader :application
    attr_reader :data
    attr_reader :environment
    attr_accessor :mutex
  end

  ECOLOGY_EXTENSION = ".ecology"

  Ecology.mutex = Mutex.new

  class << self
    # Normally this is only for testing.
    def reset
      @application = nil
      @data = nil

      @ecology_initialized = nil
    end

    def read(ecology_pathname = nil)
      return if @ecology_initialized

      mutex.synchronize do
        return if @ecology_initialized

        reset

        file_path = ENV['ECOLOGY_SPEC'] || ecology_pathname || default_ecology_name
        if File.exist?(file_path)
          contents = File.read(file_path)
          @data = MultiJson.decode(contents);

          if @data
            @application = @data["application"]

            @environment = @data["environment"]
            if !@environment && @data["environment-from"]
              from = @data["environment-from"]
              if from.respond_to?(:map)
                @environment ||= from.map {|v| ENV[v]}.compact.first
              else
                @environment = ENV[from].to_s
              end
            end
          end
        end
        @application ||= File.basename($0)
        @environment ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"

        @data = environmentize_data(@data)

        @ecology_initialized = true
      end
    end

    private

    def environmentize_data(data_in)
      if data_in.is_a?(Array)
        data_in.map { |subdata| environmentize_data(subdata) }
      elsif data_in.is_a?(Hash)
        if data_in.keys.any? { |k| k =~ /^env:/ }
          value = data_in["env:#{@environment}"] || data_in["env:*"]
          return nil unless value
          environmentize_data(value)
        else
          data_out = {}
          data_in.each { |k, v| data_out[k] = environmentize_data(v) }
          data_out
        end
      else
        data_in
      end
    end

    public

    def property(param, options = {})
      components = param.split("::")

      value = components.inject(@data) do |data, component|
        if data
          data[component]
        else
          nil
        end
      end

      return nil unless value
      return value unless options[:as]

      unless value.is_a?(Hash)
        if options[:as] == String
          return value.to_s
        elsif options[:as] == Symbol
          return value.to_sym
        elsif options[:as] == Fixnum
          return value.to_i
        elsif options[:as] == Hash
          raise "Cannot convert scalar value to Hash!"
        else
          raise "Unknown type #{options[:as].inspect} passed to Ecology.data(:as)!"
        end
      end

      return value if options[:as] == Hash
    end

    PATH_SUBSTITUTIONS = {
      "$env" => proc { Ecology.environment },
      "$cwd" => proc { Dir.getwd },
      "$app" => proc { File.dirname($0) },
    }

    def path(path_name)
      path_data = @data ? @data["paths"] : nil
      return nil unless path_data && path_data[path_name]

      path = path_data[path_name]
      PATH_SUBSTITUTIONS.each do |key, value|
        path.gsub! key, value.call
      end

      path
    end

    def default_ecology_name(executable = $0)
      suffix = File.extname(executable)
      executable[0..(executable.length - 1 - suffix.size)] +
        ECOLOGY_EXTENSION
    end

    # This is a convenience function because the Ruby
    # thread API has no accessor for the thread ID,
    # but includes it in "to_s" (buh?)
    def thread_id(thread)
      return "main" if thread == Thread.main

      str = thread.to_s

      match = nil
      match  = str.match /(0x\d+)/
      return nil unless match
      match[1]
    end
  end
end
