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

You can then access these paths with Ecology.path("app1_location") and
similar.  In the paths, "$app" will be replaced by the directory the
application is run from, "$cwd" will be replaced by the current
working directory, "$env" will be replaced by the current environment,
and "$pid" will be replaced by the current process ID.

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
    "file_path": "$app/../log_to",
    "extra_json_fields": {
      "app_tag": "splodging_apps",
      "precedence": 9
    }
  }
}

Termite can read the level via Ecology.property("logging:level"), which will
give it in whatever form it appears in the JSON.

Ecology.property("logging:extra_json_fields") would be returned as a Hash.
You can return it as a String, Symbol, Array, Fixnum or Hash by supplying
the :as option:

  Ecology.property("logging:info", :as => Symbol)  # :info
  Ecology.property("logging:stdout_level", :as => String) # "4"
  Ecology.property("logging:extra_json_fields", :as => Symbol) # error!
  Ecology.property("logging:file_path", :as => :path) # "/home/theuser/sub/log_to"

Embedded Ruby
=============

If instead of a .ecology file, you have a .ecology.erb file, it will
be parsed using Erubis and *then* parsed using JSON.  This makes it
easy to have conditional properties.

Using outside Ruby
==================

Use the with_ecology binary to pre-parse, pre-use Erb and then run
another binary with the Ecology data put into environment variables.

For example, assume you have a my.ecology.erb that looks like:

{
  "application": "<%= "bob" %>",
  "property1": {
    "foo": "bar",
    "baz": 7
  }
}

Now run the following:

  $ with_ecology my.ecology env | grep ECOLOGY

You'll see:

ECOLOGY_application=bob
ECOLOGY_application_TYPE=string
ECOLOGY_property1_foo=bar
ECOLOGY_property1_foo_TYPE=string
ECOLOGY_property1_baz=7
ECOLOGY_property1_baz_TYPE=int

This is just a translations of the ecology fields into environment
variable names.  You can usually ignore the types, but (rarely) this
can be important if you need to know whether the ecology specified a
number directly or as a string, or to find out whether a field was
a null or the empty string.

This can be useful to pass variables to non-Ruby programs, or any time
you don't want to have to link with Erubis and a JSON parser.  You'll
need to parse the properties from environment variables yourself,
though.

Environment-Specific Data
=========================

(Note: this section is mostly obsolete.  You can use Erb for this)

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

  Ecology.property("logging:stderr_level", :as => String)

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

Each field will be overridden by the "latest" value -- the top-level
Ecology overrides the Ecologies that it uses, and so on.  If multiple
Ecologies are used, the earlier Ecologies in the list override the
later Ecologies.

This can be used to set up Ecology "modules" for common functionality,
or to override certain settings in certain environments from a common
base template.

Events
======

You often want to set your ecology-related properties when the ecology
is initialized, but no earlier.  You may not know exactly when the
earliest call to Ecology.read will be.  In that case, you want to use
the on_initialize event hook:

Ecology.on_initialize do
  @my_property = Ecology.property("my:property")
end

If the ecology was already initialized before you set the
on_initialize hook, then the hook will run immediately.

There is also an on_reset hook.  Read "Testing with an Ecology" to
find out why you'd ever care about that.

Ecology.read Etiquette
======================

If you're writing an application, try to call Ecology.read early.
Libraries depending on it can then initialize themselves, now that
they know where your Ecology data is.

If you're writing a library, call Ecology.on_initialize early to make
sure you get initialized as soon as possible.  You'll probably need
your own Ecology.read call since your containing application may not
use Ecology, or have an Ecology file.  Try to make Ecology.read happen
as late as you can - the first time you genuinely need the data, for
instance.

For test purposes, if you set a bunch of data with
Ecology.on_initialize, try to register Ecology.on_reset to clear that
same data.  Then a test using Ecology.reset can test your library with
different settings.

Testing with an Ecology
=======================

The Ecology library provides a simple hook for setting up an ecology
for your application.  Just require "ecology/test_methods" into your
test or test_helper, then call set_up_ecology with the text of the
ecology as the first argument.

In production use, you'll probably never reset the ecology.  However,
in testing you may frequently want to, especially if you're testing a
library that ties closely into the ecology.

There are two basic approaches your library can take, and they affect
testing.

Termite, our logging library, copies settings from the ecology into
its instance.  Then, when you reset the ecology, you can also discard
old logger objects with old settings.

Glowworm, our feature flags library, is basically a big singleton and
uses ecology data, so it needs to reset its internal state when the
ecology is reset, and then re-read that state when the ecology is next
initialized.

Code for that for your library might look something like:

MyLib.on_reset do
  @myvar1 = nil
  @myvar2 = nil
end

MyLib.on_initialize do
  @myvar1 = Ecology.property("mylib:property1", :as => :string)
  @myvar2 = Ecology.property("mylib:property2", :as => :path)
end

Hooks persist across resets.  That is, your on_reset hook will be
called on every reset until you explicitly remove it.

Releasing within Ooyala
=======================

Ooyalans, to release Ecology to gems.sv2, use the following:

  gem build
  rake _0.8.7_ -f ../ooyala_gems.rake gem:push ecology-0.0.1.gem

Change the version to the actual version you'd like to push.
