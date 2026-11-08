#!/usr/bin/env rake
require "bundler/gem_tasks"
require "yard"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "lib/parse/stack"
  t.test_files = FileList["test/lib/**/*_test.rb"]
  t.warning = false
  t.verbose = true
end

task :default => :test

desc "Run against a disposable local Parse Server and MongoDB (npm ci --prefix test/integration first)"
task :integration do
  require "rbconfig"
  sh({ "RUBY" => RbConfig.ruby }, ENV.fetch("NODE", "node"), "test/integration/run.js")
end

task :console do
  exec "./bin/console"
end
task :c => :console

desc "List undocumented methods"
task "yard:stats" do
  exec "yard stats --list-undoc"
end

desc "Start the yard server"
task "docs" do
  exec "rm -rf ./yard && yard server --reload"
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]   # optional
  t.options = ["-o", "doc/parse-stack"] # optional
  t.stats_options = ["--list-undoc"]         # optional
end
