require "multi_json"
require "thread"

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
      @environment = nil
      @data = nil
      @triggers = {}

      @ecology_initialized = nil
    end

    def read(ecology_pathname = nil)
      return if @ecology_initialized

      mutex.synchronize do
        return if @ecology_initialized

        file_path = ENV['ECOLOGY_SPEC'] || ecology_pathname || default_ecology_name
        if File.exist?(file_path)
          @data = {}
          contents = merge_with_overrides(file_path)
        end

        @application ||= File.basename($0)
        @environment ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"

        @triggers ||= {}
        (@triggers[:initialize] || []).each do |init_block|
          init_block.call
        end

        @ecology_initialized = true
      end
    end

    def on_initialize(&block)
      mutex.synchronize do
        if @ecology_initialized
          block.call
          return
        end

        @triggers[:initialize] ||= []
        @triggers[:initialize] << block
      end
    end

    private

    def merge_with_overrides(file_path)
      contents = File.read(file_path)
      file_data = MultiJson.decode(contents);

      return unless file_data

      # First, try to set @application and @environment from the file data

      @application ||= file_data["application"]
      @environment ||= file_data["environment"]

      if !@environment && file_data["environment-from"]
        from = file_data["environment-from"]
        if from.respond_to?(:map)
          @environment ||= from.map {|v| ENV[v]}.compact.first
        else
          @environment = ENV[from] ? ENV[from].to_s : nil
        end
      end

      # Next, filter the data by the current environment
      file_data = environmentize_data(file_data)

      # Merge the file data into @data
      @data = deep_merge(@data, file_data)

      # Finally, process any inheritance/overrides
      if file_data["uses"]
        if file_data["uses"].respond_to?(:map)
          file_data["uses"].map { |file| merge_with_overrides(file) }
        else
          merge_with_overrides(file_data["uses"])
        end
      end
    end

    def deep_merge(hash1, hash2)
      all_keys = hash1.keys | hash2.keys
      ret = {}

      all_keys.each do |key|
        if hash1.has_key?(key) && hash2.has_key?(key)
          if hash1[key].is_a?(Hash) && hash2[key].is_a?(Hash)
            ret[key] = deep_merge(hash1[key], hash2[key])
          else
            ret[key] = hash1[key]
          end
        elsif hash1.has_key?(key)
          ret[key] = hash1[key]
        else
          ret[key] = hash2[key]
        end
      end

      ret
    end

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
      components = param.split(":").compact.select {|s| s != ""}

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
        if [String, :string].include?(options[:as])
          return value.to_s
        elsif [Symbol, :symbol].include?(options[:as])
          return value.to_s.to_sym
        elsif [Fixnum, :int, :integer, :fixnum].include?(options[:as])
          return value.to_i
        elsif [Hash, :hash].include?(options[:as])
          raise "Cannot convert scalar value to Hash!"
        elsif [:path].include?(options[:as])
          return string_to_path(value.to_s)
        elsif [:json].include?(options[:as])
          raise "JSON return type not yet supported!"
        else
          raise "Unknown type #{options[:as].inspect} passed to Ecology.data(:as) for property #{property}!"
        end
      end

      return value if options[:as] == Hash
      raise "Couldn't convert JSON fields to #{options[:as].inspect} for property #{property}!"
    end

    PATH_SUBSTITUTIONS = {
      "$env" => proc { Ecology.environment },
      "$cwd" => proc { Dir.getwd },
      "$app" => proc { File.dirname($0) },
      "$pid" => proc { Process.pid.to_s },
    }

    def path(path_name)
      path_data = @data ? @data["paths"] : nil
      return nil unless path_data && path_data[path_name]

      string_to_path path_data[path_name]
    end

    private

    def string_to_path(path)
      PATH_SUBSTITUTIONS.each do |key, value|
        path.gsub! key, value.call
      end

      path
    end

    public

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
