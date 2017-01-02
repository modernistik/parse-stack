#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/parse/stack'
  t.test_files = FileList['test/lib/**/*_test.rb']
  t.warning = false
  t.verbose = true
end

task :default => :test

task :console do
  exec './bin/console'
end
task :c => :console

desc 'List undocumented methods'
task 'doc:stats' do
  exec 'yard stats --list-undoc'
end

desc 'Start the yard server'
task 'doc:server' do
  exec 'rm -rf ./yard && yard server --reload'
end
