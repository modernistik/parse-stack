# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'
require_relative 'user'
module Parse
  # This class represents the data and columns contained in the standard Parse `_Role` collection.
  class Role < Parse::Object
    
    parse_class Parse::Model::CLASS_ROLE
    # @return [String] the name of this role.
    property :name
    # The roles Parse relation provides a mechanism to create a hierarchical inheritable types of permissions
    # by assigning child roles.
    # @return [RelationCollectionProxy<Role>] a collection of Roles.
    has_many :roles, through: :relation
    # @return [RelationCollectionProxy<User>] a Parse relation of users belonging to this role.
    has_many :users, through: :relation

    before_save do
      acl.everyone true, false
    end

  end

end
