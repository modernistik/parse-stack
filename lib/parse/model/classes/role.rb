# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'
require_relative 'user'
module Parse

  class Role < Parse::Object
    parse_class Parse::Model::CLASS_ROLE
    property :name

    has_many :roles, through: :relation
    has_many :users, through: :relation

    before_save do
      acl.everyone true, false
    end

  end

end
