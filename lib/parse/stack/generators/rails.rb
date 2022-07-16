# encoding: UTF-8
# frozen_string_literal: true

require "parse/stack"
require "parse/stack/tasks"
require "rails/generators"
require "rails/generators/named_base"

# Module namespace to show up in the generators list for Rails.
module ParseStack
  # Adds support for rails when installing Parse::Stack to a Rails project.
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    desc "This generator creates an initializer file at config/initializers"
    # @!visibility private
    def generate_initializer
      copy_file "parse.rb", "config/initializers/parse.rb"
      #copy_file "model_user.rb", File.join("app/models", "user.rb")
      #copy_file "model_role.rb", File.join("app/models", "role.rb")
      #copy_file "model_session.rb", File.join("app/models", "session.rb")
      #copy_file "model_installation.rb", File.join("app/models", "installation.rb")
      #copy_file "webhooks.rb", File.join("app/models", "webhooks.rb")
    end
  end

  # @!visibility private
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path(__dir__ + "/templates")
    desc "Creates a Parse::Object model subclass."
    argument :attributes, type: :array, default: [], banner: "field:type field:type"
    check_class_collision

    # @!visibility private
    def create_model_file
      @allowed_types = Parse::Properties::TYPES - [:acl, :id, :relation]
      template "model.erb", File.join("app/models", class_path, "#{file_name}.rb")
    end
  end
end
