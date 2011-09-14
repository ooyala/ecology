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
  }
}

Absolutely every part of it is optional, including the presence of the file at all.

You can override the application name, as shown above.

Releasing within Ooyala
=======================

Ooyalans, to release Ecology to gems.sv2, use the following:

  gem build
  rake _0.8.7_ -f ../ooyala_gems.rake gem:push ecology-0.0.1.gem

Change the version to the actual version you'd like to push.
