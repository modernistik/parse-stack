# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'
require_relative "model"
require 'open-uri'
# Parse File objects are the only non Parse::Object subclass that has a save method.
# In general, a Parse File needs content and a specific mime-type to be created. When it is saved, it
# is sent to AWS/S3 to be saved (by Parse), and the result is a new URL pointing to that file.
# This however is return as a type of File pointer object (hash format)
# It only has two fields, the absolute URL of the file and the basename of the file.
# The contents and mime_type are only present when creating a new file locally and are not
# stored as part of the parse pointer.
module Parse

    class File < Model
      ATTRIBUTES = {  __type: :string, name: :string, url: :string }.freeze
      attr_accessor :name, :url
      attr_accessor :contents, :mime_type
      def self.parse_class; TYPE_FILE; end;
      def parse_class; self.class.parse_class; end;
      alias_method :__type, :parse_class
      FIELD_NAME = "name"
      FIELD_URL = "url"
      class << self
        attr_accessor :default_mime_type

        def default_mime_type
          @default_mime_type ||= "image/jpeg"
        end
      end
      # The initializer to create a new file supports different inputs.
      # If the first paramter is a string which starts with 'http', we then download
      # the content of the file (and use the detected mime-type) to set the content and mime_type fields.
      # If the first parameter is a hash, we assume it might be the Parse File hash format which contains url and name fields only.
      # If the first paramter is a Parse::File, then we copy fields over
      # Otherwise, creating a new file requires a name, the actual contents (usually from a File.open("local.jpg").read ) and the mime-type
      def initialize(name, contents = nil, mime_type = nil)
        mime_type ||= Parse::File.default_mime_type

        if name.is_a?(String) && name.start_with?("http") #could be url string
          file = open( name )
          @contents =  file.read
          @name = File.basename file.base_uri.to_s
          @mime_type = file.content_type
        elsif name.is_a?(Hash)
          self.attributes = name
        elsif name.is_a?(::File)
          @contents =  contents || name.read
          @name = File.basename name.to_path
        elsif name.is_a?(Parse::File)
          @name = name.name
          @url = name.url
        else
          @name = name
          @contents = contents
        end
        if @name.blank?
          raise "Invalid Parse::File initialization with name '#{@name}'"
        end

        @mime_type ||= mime_type

      end

      # This creates a new Parse File Object with from a URL, saves it and returns it
      def self.create(url)
        url = url.url if url.is_a?(Parse::File)
        file = self.new(url)
        file.save
        file
      end

      # A File object is considered saved if the basename of the URL and the name parameters are equal and
      # the name of the file begins with 'tfss'
      def saved?
        @url.present? && @name.present? && @name == File.basename(@url) && @name.start_with?("tfss")
      end

      def attributes
        ATTRIBUTES
      end

      def ==(u)
        return false unless u.is_a?(self.class)
        @url == u.url
      end

      def attributes=(h)
        if h.is_a?(String)
          @url = h
          @name = File.basename(h)
        elsif h.is_a?(Hash)
          @url = h[FIELD_URL] || h[:url] || @url
          @name = h[FIELD_NAME] || h[:name] || @name
        end
      end

      # This is a proxy to the ruby ::File.basename method
      def self.basename(file_name, suffix = nil)
       if suffix.nil?
         ::File.basename(file_name)
       else
         ::File.basename(file_name, suffix)
       end
      end

      # save (create) the file if it has all the proper fields. You cannot update Parse Files.
      def save
        unless saved? || @contents.nil? || @name.nil?
          response = client.create_file(@name, @contents, @mime_type)
          unless response.error?
            result = response.result
            @name = result[FIELD_NAME] || File.basename(result[FIELD_URL])
            @url = result[FIELD_URL]
          end
        end
        saved?
      end

      def inspect
        "<Parse::File @name='#{@name}' @mime_type='#{@mime_type}' @contents=#{@contents.nil?} @url='#{@url}'>"
      end

      def to_s
        @url
      end

    end

end


class Hash
  # {"name"=>"tfss-cat.jpg", "url"=>"http://files.parsetfss.com/bcf638bb-3db0-4042-b846-7840b345b0d6/tfss-cat.jpg"}
  # This is a helper method that determines whether a hash looks like a Parse::File hash
  def parse_file?
    url = self[Parse::File::FIELD_URL]
    name = self[Parse::File::FIELD_NAME]
    (count == 2 || self["__type"] == Parse::File.parse_class) &&
    url.present? && name.present? &&
    name == ::File.basename(url) && name.start_with?("tfss")
  end
end
