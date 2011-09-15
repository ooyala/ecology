Ecology
=======

Ecology is a gem to handle configuration variables.  At Ooyala, we use
it for setting application metadata about logging, monitoring,
testing, deployment and other "outside the application"
infrastructure.  So it's the application's ecology, right?

Installing
==========

"gem install ecology" works pretty well.  You can also specify Ecology
from a Gemfile if you're using Bundler.

Ooyalans should make sure that "gems.sv2" is listed as a gem source in
your Gemfile or on your gem command line.

Finding Your Ecology
====================

By default an application called "bob.sh" will have an ecology file in
the same directory called "bob.ecology".  Ecology just strips off the
final file extension, replaces it with ".ecology", and looks there.

You can also specify a different location in your Ecology.read call,
or set the ECOLOGY_SPEC environment variable to a different location.

An Ecology is a JSON file of roughly this structure:

{
  "application": "MyApp",
  "environment-from": "RACK_ENV",
  "logging": {
    "default_component": "SplodgingLib",
    "extra_json_fields": {
      "app_group": "SuperSpiffyGroup",
      "precedence": 7
    },
    "console_print": "off",
    "filename": "/tmp/bobo.txt",
    "stderr_level": "fatal"
  },
  "monitoring": {
    "zookeeper-host": "zookeeper-dev.sv2"
  }
}

Absolutely every part of it is optional, including the presence of the file at all.

You can override the application name, as shown above.

Paths
=====

If you have a configurable per-environment path, you probably want it in the "paths"
section of your ecology.  For instance:

{
  "application": "SomeApp",
  "paths": {
    "pid_location": "/pid_dir/",
    "app1_location": "$app/../dir1",
    "app1_log_path": "$cwd/logs"
  }
}

You can then access these paths with Ecology.path("app1_location") and similar.
In the paths, "$app" will be replaced by the directory the application is run
from, "$cwd" will be replaced by the current working directory, and "$env" will
be replaced by the current environment.

Reading Data
============

If your library is configured via Ecology, you'll likely want to read data
from it.  For instance, let's look at the Termite logging library's method
of configuration:

{
  "application": "SomeApp",
  "logging": {
    "level": "info",
    "stderr_level": "warn",
    "stdout_level": 4,
    "extra_json_fields": {
      "app_tag": "splodging_apps",
      "precedence": 9
    }
  }
}

Termite can read the level via Ecology.property("logging::level"), which will
give it in whatever form it appears in the JSON.
Ecology.property("logging::extra_json_fields") would be returned as a Hash.
You can return it as a String, Symbol, Array, Fixnum or Hash by supplying
the :as option:

  Ecology.property("logging::info", :as => Symbol)  # :info
  Ecology.property("logging::stdout_level", :as => String) # "4"
  Ecology.property("logging::extra_json_fields", :as => Symbol) # error!

Environment-Specific Data
=========================

Often you'll want to supply a different path, hostname or other
configuration variable depending on what environment you're
currently deployed to - staging may want a different MemCacheD
server than development, say.

Here's another logging example:

{
  "application": "Ooyala Rails",
  "environment-from": ["RAILS_ENV", "RACK_ENV"],
  "logging": {
    "console_out": {
      "env:development": true,
      "env:*": false
    },
    "stderr_level": {
      "env:development": "fatal",
      "env:production": "warn"
    },
    "stdout_level": "info"
  }
}

In this case, data can be converted from a Hash into a Fixnum
or String automatically:

  Ecology.property("logging::stderr_level", :as => String)

Ecology returns "fatal" or "warn" here, depending on the value
of RAILS_ENV or RACK_ENV.

Using Other Ecologies
=====================

The data in a given Ecology file can build on one or more
other Ecology files.

{
  "application": "SomeApp",
  "environment-from": [ "APP_ENV", "RACK_ENV" ],
  "uses": [ "ecologies/logging.ecology", "ecologies/monitoring.ecology" ]
}

For now, fields are overridden at the top level.  So you can't
split the top-level "logging" field between two different Ecology files.
Each top-level field should occur in only one Ecology file, or it
will be overridden completely by the "latest" value -- the top-level
Ecology overrides the Ecologies that it uses, and so on down the
hierarchy.

If multiple Ecologies are used, the earlier Ecologies in the list
override the later Ecologies.

This can be used to set up Ecology "modules" for common functionality,
or to override certain settings in certain environments from a common
base template.

Unfinished Features
===================

* You should be able to use a few special values for :as:

  Ecology.property("logging::file_path", :as => :path)
  Ecology.property("logging::extra_fields", :as => :json)


Releasing within Ooyala
=======================

Ooyalans, to release Ecology to gems.sv2, use the following:

  gem build
  rake _0.8.7_ -f ../ooyala_gems.rake gem:push ecology-0.0.1.gem

Change the version to the actual version you'd like to push.
