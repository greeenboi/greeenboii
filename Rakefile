# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "rake/extensiontask"

task build: :compile

GEMSPEC = Gem::Specification.load("greeenboii.gemspec")

Rake::ExtensionTask.new("greeenboii", GEMSPEC) do |ext|
  ext.lib_dir = "lib/greeenboii"
end

task default: %i[clobber compile test rubocop]
