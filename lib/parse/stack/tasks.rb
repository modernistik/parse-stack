# encoding: UTF-8
# frozen_string_literal: true

require_relative "../stack.rb"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require "rake"
require "rake/dsl_definition"

module Parse
  module Stack
    # Loads and installs all Parse::Stack related tasks in a rake file.
    def self.load_tasks
      Parse::Stack::Tasks.new.install_tasks
    end

    # Defines all the related Rails tasks for Parse.
    class Tasks
      include Rake::DSL if defined? Rake::DSL

      # Installs the rake tasks.
      def install_tasks
        if defined?(::Rails)
          unless Rake::Task.task_defined?("db:seed") || Rails.root.blank?
            namespace :db do
              desc "Seeds your database with by loading db/seeds.rb"
              task :seed => "parse:env" do
                load Rails.root.join("db", "seeds.rb")
              end
            end
          end
        end

        namespace :parse do
          task :env do
            if Rake::Task.task_defined?("environment")
              Rake::Task["environment"].invoke
              if defined?(::Rails)
                Rails.application.eager_load! if Rails.application.present?
              end
            end
          end

          task :verify_env => :env do
            unless Parse::Client.client?
              raise "Please make sure you have setup the Parse.setup configuration before invoking task. Usually done in the :environment task."
            end

            endpoint = ENV["HOOKS_URL"] || ""
            unless endpoint.starts_with?("http://") || endpoint.starts_with?("https://")
              raise "The ENV variable HOOKS_URL must be a <http/s> url : '#{endpoint}'. Ex. https://12345678.ngrok.io/webhooks"
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
              endpoint = ENV["HOOKS_URL"]
              puts "Registering Parse Webhooks @ #{endpoint}"
              Rake::Task["parse:webhooks:register:functions"].invoke
              Rake::Task["parse:webhooks:register:triggers"].invoke
            end

            desc "List all webhooks and triggers registered with the Parse Server"
            task :list => :verify_env do
              Rake::Task["parse:webhooks:list:functions"].invoke
              Rake::Task["parse:webhooks:list:triggers"].invoke
            end

            desc "Remove all locally registered webhooks from the Parse Application."
            task :remove => :verify_env do
              Rake::Task["parse:webhooks:remove:functions"].invoke
              Rake::Task["parse:webhooks:remove:triggers"].invoke
            end

            namespace :list do
              task :functions => :verify_env do
                endpoint = ENV["HOOKS_URL"] || "-"
                Parse.client.functions.each do |r|
                  name = r["functionName"]
                  url = r["url"]
                  star = url.starts_with?(endpoint) ? "*" : " "
                  puts "[#{star}] #{name} -> #{url}"
                end
              end

              task :triggers => :verify_env do
                endpoint = ENV["HOOKS_URL"] || "-"
                triggers = Parse.client.triggers.results
                triggers.sort! { |x, y| [x["className"], x["triggerName"]] <=> [y["className"], y["triggerName"]] }
                triggers.each do |r|
                  name = r["className"]
                  trigger = r["triggerName"]
                  url = r["url"]
                  star = url.starts_with?(endpoint) ? "*" : " "
                  puts "[#{star}] #{name}.#{trigger} -> #{url}"
                end
              end
            end

            namespace :register do
              task :functions => :verify_env do
                endpoint = ENV["HOOKS_URL"]
                Parse::Webhooks.register_functions!(endpoint) do |name|
                  puts "[+] function - #{name}"
                end
              end

              task :triggers => :verify_env do
                endpoint = ENV["HOOKS_URL"]
                Parse::Webhooks.register_triggers!(endpoint, include_wildcard: true) do |trigger, name|
                  puts "[+] #{trigger.to_s.ljust(12, " ")} - #{name}"
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
                Parse::Webhooks.remove_all_triggers! do |trigger, name|
                  puts "[-] #{trigger.to_s.ljust(12, " ")} - #{name}"
                end
              end
            end
          end # webhooks
        end # webhooks namespace
      end
    end # Tasks
  end # Webhooks
end # Parse
