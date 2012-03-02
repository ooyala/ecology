require "multi_json"
require "thread"
require "ecology/version"

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
      # Preserve triggers across resets by default
      @triggers ||= {}

      @application = nil
      @environment = nil
      @data = nil
      @ecology_initialized = nil
      @ecology_path = nil

      publish_event :reset
    end

    # This function is called in applications or libraries to initialize the ecology
    def read(ecology_pathname = nil)
      filelist = [ENV["ECOLOGY_SPEC"], ecology_pathname, default_ecology_name]
      ecology_path = filelist.detect { |file_path|
        file_path && (File.exist?(file_path) || File.exist?(file_path + ".erb"))
      }

      if @ecology_initialized
        if ecology_path != nil && File.expand_path(ecology_path) != File.expand_path(@ecology_path)
          raise "You've tried to load both #{ecology_path.inspect || "nothing"} and " +
            "#{@ecology_path.inspect || "nothing"} as ecology files since last reset!"
        end
        return
      end

      should_publish_event = false

      mutex.synchronize do
        return if @ecology_initialized

        @ecology_path = ecology_path
        @data ||= {}
        merge_with_overrides!(@ecology_path) if @ecology_path

        @application ||= File.basename($0)
        @environment ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"

        should_publish_event = true

        @ecology_initialized = true
      end

      # Do this outside the mutex to reduce the likelihood
      # of deadlocks.  This will run all of the on_initialize triggers.
      publish_event(:initialize) if should_publish_event
    end

    # These functions are called to set and remove triggers that are called when
    # the specified event has occurred.
    def on_initialize(token = nil, &block)
      on_event(:initialize, token, &block)
    end

    def on_reset(token = nil, &block)
      on_event(:reset, token, &block)
    end

    def remove_trigger(token)
      @triggers ||= {}
      @triggers.each do |event, trigger_list|
        @triggers[event].delete(token)
      end
    end

    def clear_triggers
      @triggers = {}
    end

    private

    def on_event(event, token = nil, &block)
      mutex.synchronize do
        @token_offset ||= 0
        token ||= "token#{@token_offset}"

        @triggers ||= {}
        @triggers[event] ||= {}
        @triggers[event][token] = block

        if event == :initialize && @ecology_initialized
          block.call
        end
      end
    end

    # This function tells Ecology that a certain event (i.e. intialization) has happened.
    # It will then proceed to run all of the triggers that have been set in the application for this event.
    def publish_event(event)
      @triggers ||= {}

      # This doesn't lock the mutex, because there's too high
      # a chance of somebody calling Ecology.read or on_event
      # or something while we're doing this.  That would
      # deadlock, which is no good.
      (@triggers[event] || {}).each do |token, event_block|
        event_block.call
      end
    end

    # This function populates the @data, @application, and @environment objects,
    # which are populated from the ecology file. It prefers earlier values (top-level first),
    # to values defined in inherited ecologies. This function does not return anything,
    # but modifies @data directly.
    def merge_with_overrides!(file_path)
      if File.exist?(file_path + ".erb")
        contents = File.read(file_path + ".erb")

        require "erubis"
        var_hash = {
          :ecology_version => Ecology::VERSION,
          :filename => "#{file_path}.erb",
        }
        contents = Erubis::Eruby.new(contents).result(var_hash)
      else
        contents = File.read(file_path)
      end
      file_data = MultiJson.decode(contents);

      return unless file_data

      # First, try to set @application and @environment from the file data

      @application ||= file_data["application"]
      @environment ||= file_data["environment"]

      if !@environment && file_data["environment-from"]
        from = file_data["environment-from"]
        if from.respond_to?(:map)
          @environment ||= from.map {|env_var| ENV[env_var]}.compact.first
        else
          @environment ||= ENV[from] ? ENV[from].to_s : nil
        end
      end

      # Next, filter the data by the current environment
      file_data = environmentize_data(file_data)

      # Merge the file data into @data, preferring previous values in @data to new values from the file.
      @data = deep_merge(@data, file_data)

      # Finally, process any inheritance, without overriding already set values.
      if file_data["uses"]
        if file_data["uses"].respond_to?(:map)
          file_data["uses"].map { |file| merge_with_overrides!(file) }
        else
          merge_with_overrides!(file_data["uses"])
        end
      end
    end

    # Merge two hashes, resolving conflicts by picking the value from the first.
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

    # This function crawls through input_data, and chooses values for environment-based keys.
    def environmentize_data(input_data)
      if input_data.is_a?(Array)
        input_data.map { |subdata| environmentize_data(subdata) }
      elsif input_data.is_a?(Hash)
        if input_data.keys.any? { |k| k =~ /^env:/ }
          value = input_data["env:#{@environment}"] || input_data["env:*"]
          return nil unless value
          environmentize_data(value)
        else
          output_data = {}
          input_data.each { |k, v| output_data[k] = environmentize_data(v) }
          output_data
        end
      else
        input_data
      end
    end

    public

    # Returns the value of a specified property, with nestings denoted with colons.
    # This can be requested with :as => <type> as an option.
    def property(param, options = {})
      components = param.split(":").compact.select {|s| s != ""}

      value = components.inject(@data) do |data_hash, component|
        if data_hash
          data_hash[component]
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
          raise "Unknown type #{options[:as].inspect} passed to Ecology.property(:as) for property #{param}!"
        end
      end

      return value if options[:as] == Hash
      raise "Couldn't convert JSON fields to #{options[:as].inspect} for property #{param}!"
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
