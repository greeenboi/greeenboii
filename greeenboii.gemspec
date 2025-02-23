# frozen_string_literal: true

require_relative "lib/greeenboii/version"

Gem::Specification.new do |spec|
  spec.name = "greeenboii"
  spec.version = Greeenboii::VERSION
  spec.authors = ["greeenboi"]
  spec.email = ["suvan.gowrishanker.204@gmail.com"]

  spec.summary = "Greeenboii is a cli tool that i will use to perform all kinds of scripts that i use daily"
  spec.description = "Greeenboii will have several features that i will use to perform daily tasks"
  spec.homepage = "https://www.suvangs.tech"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["github_repo"] = "ssh://https://github.com/greeenboi/greeenboii"
  spec.metadata["source_code_uri"] = "https://github.com/greeenboi/greeenboii"
  spec.metadata["changelog_uri"] = "https://github.com/greeenboi/greeenboii/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/greeenboii/extconf.rb"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
