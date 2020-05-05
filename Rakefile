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
