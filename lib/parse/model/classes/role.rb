# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'
require_relative 'user'
module Parse
  # This class represents the data and columns contained in the standard Parse `_Role` collection.
  # Roles allow the an application to group a set of {Parse::User} records with the same set of
  # permissions, so that specific records in the database can have {Parse::ACL}s related to a role
  # than trying to add all the users in a group.
  class Role < Parse::Object

    parse_class Parse::Model::CLASS_ROLE
    # @!attribute name
    # @return [String] the name of this role.
    property :name
    # This attribute is mapped as a `has_many` Parse relation association with the {Parse::Role} class,
    # as roles can be associated with multiple child roles to support role inheritance.
    # The roles Parse relation provides a mechanism to create a hierarchical inheritable types of permissions
    # by assigning child roles.
    # @return [RelationCollectionProxy<Role>] a collection of Roles.
    has_many :roles, through: :relation
    # This attribute is mapped as a `has_many` Parse relation association with the {Parse::User} class.
    # @return [RelationCollectionProxy<User>] a Parse relation of users belonging to this role.
    has_many :users, through: :relation

    def apply_default_acls
      acl.everyone true, false
    end

  end

end
