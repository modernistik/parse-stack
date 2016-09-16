# encoding: UTF-8
# frozen_string_literal: true

module Parse
  module Stack
    class Railtie < ::Rails::Railtie

      rake_tasks do
        require_relative 'tasks'
        Parse::Stack.load_tasks
      end

      generators do
        require_relative 'generators/rails'
      end

    end
  end
end
