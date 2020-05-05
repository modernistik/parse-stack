# encoding: UTF-8
# frozen_string_literal: true

module Parse
  module Stack
    # Support for adding rake tasks to a Rails project.
    class Railtie < ::Rails::Railtie
      rake_tasks do
        require_relative "tasks"
        Parse::Stack.load_tasks
      end

      generators do
        require_relative "generators/rails"
      end
    end
  end
end
