# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "parse/stack/version"

Gem::Specification.new do |spec|
  spec.name = "parse-stack"
  spec.version = Parse::Stack::VERSION
  spec.authors = ["Anthony Persaud"]
  spec.email = ["persaud@modernistik.com"]

  spec.summary = %q{Parse Server Ruby Client SDK}
  spec.description = %q{Parse Server Ruby Client. Perform Object-relational mapping between Parse Server and Ruby classes, with authentication, cloud code webhooks, push notifications and more built in.}
  spec.homepage = "https://github.com/modernistik/parse-stack"
  spec.license = "MIT"
  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "http://www.modernistik.com"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = "bin"
  spec.executables = ["parse-console"] #spec.files.grep(%r{^bin/pstack/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.5.0"

  spec.add_runtime_dependency "activemodel", [">= 5", "< 7"]
  spec.add_runtime_dependency "active_model_serializers", [">= 0.9", "< 1"]
  spec.add_runtime_dependency "activesupport", [">= 5", "< 7"]
  spec.add_runtime_dependency "parallel", [">= 1.6", "< 2"]
  spec.add_runtime_dependency "faraday", [">= 0.8", "< 2"]
  spec.add_runtime_dependency "faraday_middleware", [">= 0.9", "< 2"]
  spec.add_runtime_dependency "moneta", "< 2"
  spec.add_runtime_dependency "rack", ">= 2.0.6", "< 3"

  #   spec.post_install_message = <<UPGRADE
  #
  # ** BREAKING CHANGES **
  #  The default `has_many` association form has changed from :array to :query.
  #  To use arrays, you must now pass `through: :array` option to `has_many`.
  #
  #  Visit: https://github.com/modernistik/parse-stack/wiki/Changes-to-has_many-in-1.5.0
  #
  # UPGRADE
end

## Development
# After checking out the repo, run `bin/setup` to install dependencies. You can
# also run `bin/console` for an interactive prompt that will allow you to experiment.
#
# To install this gem onto your local machine, run `bundle exec rake install`.
# To release a new version, update the version number in `version.rb`, and then run
# `bundle exec rake release`, which will create a git tag for the version,
# push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
