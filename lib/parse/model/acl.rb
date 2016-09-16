# encoding: UTF-8
# frozen_string_literal: true

# An ACL represents the Parse Permissions object used for each record. In Parse,
# it is composed a hash-like object that represent Parse::User objectIds and/or Parse::Role
# names. For each entity (ex. User/Role/Public), you can define read/write priviledges on a particular record.
# The way they are implemented here is through an internal hash, with each value being of type Parse::ACL::Permission object.
# A Permission object contains two accessors - read and write - and knows how to generate its JSON
# structure. In Parse, if you want to give priviledges for an action (ex. read/write), then you set it to true.
# If you want to deny a priviledge, then you set it to false. One important thing is that when
# being converted to the Parse format, removing a priviledge means omiting it from the final
# JSON structure.
# The class below also implements a type of delegate pattern in order to inform the main Parse::Object
# of dirty tracking.
module Parse

  class ACL
    # The internal permissions hash and delegate accessors
    attr_accessor :permissions, :delegate
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON
    PUBLIC = "*" # Public priviledges are '*' key in Parse

    # provide a set of acls and the delegate (for dirty tracking)
    # { '*' => { "read": true, "write": true } }
    def initialize(acls = {}, owner: nil)
      everyone(true, true) # sets Public read/write
      @delegate = owner
      if acls.is_a?(Hash)
        self.attributes = acls
      end

    end

    # helper
    def self.permission(read, write = nil)
        ACL::Permission.new(read, write)
    end

    def permissions
      @permissions ||= {}
    end

    def ==(other_acl)
      return false unless other_acl.is_a?(self.class)
      return false if permissions.keys != other_acl.permissions.keys
      permissions.keys.all? { |per| permissions[per] == other_acl.permissions[per] }
    end

    # method to set the Public read/write priviledges ('*'). Alias is 'world'
    def everyone(read, write)
      apply(PUBLIC, read, write)
      permissions[PUBLIC]
    end
    alias_method :world, :everyone

    # dirty tracking. We will tell the delegate through the acl_will_change!
    # method
    def will_change!
      @delegate.acl_will_change! if @delegate.respond_to?(:acl_will_change!)
    end

    # removes a permission
    def delete(id)
      id = id.id if id.is_a?(Parse::Pointer)
      if id.present? && permissions.has_key?(id)
        will_change!
        permissions.delete(id)
      end
    end

    # apply a new permission with a given objectId (or tag)
    def apply(id, read = nil, write = nil)
      id = id.id if id.is_a?(Parse::Pointer)
      return unless id.present?
      # create a new Permissions
      permission = ACL.permission(read, write)
      # if the input is already an Permission object, then set it directly
      permission = read if read.is_a?(Parse::ACL::Permission)

      if permission.is_a?(ACL::Permission)
        if permissions[id.to_s] != permission
          will_change! # dirty track
          permissions[id.to_s] = permission
        end
      end

      permissions
    end; alias_method :add, :apply

    # You can apply a Role as a permission ex. "Admin". This will add the
    # ACL of 'role:Admin' as the key in the permissions hash.
    def apply_role(name, read = nil, write = nil)
      apply("role:#{name}", read, write)
    end; alias_method :add_role, :apply_role
    # Used for object conversion when formatting the input/output value in Parse::Object properties
    def self.typecast(value, delegate = nil)
      ACL.new(value, owner: delegate)
    end

    # Used for JSON serialization. Only if an attribute is non-nil, do we allow it
    # in the Permissions hash, since omission means denial of priviledge. If the
    # permission value has neither read or write, then the entire record has been denied
    # all priviledges
    def attributes
      permissions.select {|k,v| v.present? }.as_json
    end

    def attributes=(h)
      return unless h.is_a?(Hash)
      will_change!
      @permissions ||= {}
      h.each do |k,v|
        apply(k,v)
      end
    end

    def inspect
      "ACL(#{as_json.inspect})"
    end

    def as_json(*args)
      permissions.select {|k,v| v.present? }.as_json
    end

    def present?
      permissions.values.any? { |v| v.present? }
    end

    # Permission class
    class Permission
      include ::ActiveModel::Model
      include ::ActiveModel::Serializers::JSON
      # we don't support changing priviledges directly since it would become
      # crazy to track for dirty tracking
      attr_reader :read, :write

      # initialize with read and write priviledge
      def initialize(r = nil, w = nil)
        if r.is_a?(Hash)
          r.symbolize_keys!
          # @read = true if r[:read].nil? || r[:read].present?
          # @write = true if r[:write].nil? || r[:write].present?
          @read = r[:read].present?
          @write = r[:write].present?
        else
          # @read = true if r.nil? || r.present?
          # @write = true if w.nil? || w.present?
          @read = r.present?
          @write = w.present?
        end
      end

      def ==(per)
        return false unless per.is_a?(self.class)
        @read == per.read && @write == per.write
      end

      # omission or false on a priviledge means don't include it
      def as_json(*args)
        h = {}
        h[:read] = true if @read
        h[:write] = true if @write
        h.empty? ? nil : h.as_json
      end

      def attributes
        h = {}
        h.merge!(read: :boolean) if @read
        h.merge!(write: :boolean) if @write
        h
      end

      def inspect
        as_json.inspect
      end

      def present?
        @read.present? || @write.present?
      end

    end
  end
end
