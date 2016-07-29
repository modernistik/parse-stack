require_relative '../stack.rb'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'rake'
require 'rake/dsl_definition'

module Parse

  module Stack

    def self.load_tasks
      Parse::Stack::Tasks.new.install_tasks
    end

    class Tasks
      include Rake::DSL if defined? Rake::DSL

      def install_tasks

        namespace :parse do

          task :env do
            if Rake::Task.task_defined?('environment')
              Rake::Task['environment'].invoke
            end
          end

          task :verify_env => :env do

            unless Parse::Client.session?
              raise "Please make sure you have setup the Parse.setup configuration before invoking task. Usually done in the :environment task."
            end

            endpoint = ENV['HOOKS_URL']
            unless endpoint.empty? || endpoint.starts_with?('https://')
              raise "The ENV variable HOOKS_URL must be a <https> url : '#{endpoint}'. Ex. https://12345678.ngrok.io/webhooks"
            end

          end

          desc "Run auto_upgrade on all of your Parse models."
          task :upgrade => :env do
            puts "Auto Upgrading Parse schemas..."
            Parse.auto_upgrade! do |k|
              puts "[+] #{k}"
            end
          end

          namespace :webhooks do

          desc "Register local webhooks with Parse server"
          task :register => :verify_env do
            endpoint = ENV['HOOKS_URL']
            puts "Registering Parse Webhooks @ #{endpoint}"
            Rake::Task['webhooks:register:functions'].invoke
            Rake::Task['webhooks:register:triggers'].invoke
          end

          desc "Remove all locally registered webhooks from the Parse Application"
          task :remove => :verify_env do
            Rake::Task['webhooks:remove:functions'].invoke
            Rake::Task['webhooks:remove:triggers'].invoke
          end

          namespace :register do

            task :functions => :verify_env do
              endpoint = ENV['HOOKS_URL']
              Parse::Webhooks.register_functions!(endpoint) do |name|
                puts "[+] function - #{name}"
              end
            end

            task :triggers => :verify_env do
              endpoint = ENV['HOOKS_URL']
              Parse::Webhooks.register_triggers!(endpoint, {include_wildcard: true}) do |trigger,name|
                puts "[+] #{trigger.to_s.ljust(12, ' ')} - #{name}"
              end
            end

          end

          namespace :remove do

            task :functions => :verify_env do
              Parse::Webhooks.remove_all_functions! do |name|
                puts "[-] function - #{name}"
              end
            end

            task :triggers => :verify_env do
              Parse::Webhooks.remove_all_triggers! do |trigger,name|
                puts "[-] #{trigger.to_s.ljust(12, ' ')} - #{name}"
              end
            end

          end

          end # webhooks

        end # webhooks namespace
      end
    end # Tasks
  end # Webhooks

end # Parse
