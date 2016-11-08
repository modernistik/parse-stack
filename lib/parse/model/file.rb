# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'
require_relative "model"
require 'open-uri'

module Parse
    # This class represents a Parse file pointer. `Parse::File` has helper
    # methods to upload Parse files directly to Parse and manage file
    # associations with your classes.
    # @example
    #  file = File.open("file_path.jpg")
    #  contents = file.read
    #  file = Parse::File.new("myimage.jpg", contents , "image/jpeg")
    #  file.saved? # => false
    #  file.save
    #
    #  file.url # https://files.parsetfss.com/....
    #
    #  # or create and upload a remote file (auto-detected mime type)
    #  file = Parse::File.create(some_url)
    #
    #
    # @note The default MIME type for all files is _image/jpeg_. This can be default
    #       can be changed by setting a value to `Parse::File.default_mime_type`.
    class File < Model
      # Regular expression that matches the old legacy Parse hosted file name
      LEGACY_FILE_RX = /^tfss-[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}-/
      # The default attributes in a Parse File hash.
      ATTRIBUTES = {  __type: :string, name: :string, url: :string }.freeze
      # @return [String] the name of the file including extension (if any)
      attr_accessor :name
      # @return [String] the url resource of the file.
      attr_accessor :url

      # @return [Object] the contents of the file.
      attr_accessor :contents

      # @return [String] the mime-type of the file whe
      attr_accessor :mime_type
      # @return [Model::TYPE_FILE]
      def self.parse_class; TYPE_FILE; end;
      # @return [Model::TYPE_FILE]
      def parse_class; self.class.parse_class; end;
      alias_method :__type, :parse_class
      # @!visibility private
      FIELD_NAME = "name"
      # @!visibility private
      FIELD_URL = "url"
      class << self

        # @return [String] the default mime-type
        attr_accessor :default_mime_type

        # @return [Boolean] whether to force all urls to be https.
        attr_accessor :force_ssl

        # @return [String] The default mime type for created instances. Default: _'image/jpeg'_
        def default_mime_type
          @default_mime_type ||= "image/jpeg"
        end

        # @return [Boolean] When set to true, it will make all calls to File#url
        def force_ssl
          @force_ssl ||= false
        end

      end
      # The initializer to create a new file supports different inputs.
      # If the first paramter is a string which starts with 'http', we then download
      # the content of the file (and use the detected mime-type) to set the content and mime_type fields.
      # If the first parameter is a hash, we assume it might be the Parse File hash format which contains url and name fields only.
      # If the first paramter is a Parse::File, then we copy fields over
      # Otherwise, creating a new file requires a name, the actual contents (usually from a File.open("local.jpg").read ) and the mime-type
      # @param name [String]
      # @param contents [Object]
      # @param mime_type [String] Default see default_mime_type
      def initialize(name, contents = nil, mime_type = nil)
        mime_type ||= Parse::File.default_mime_type

        if name.is_a?(String) && name.start_with?('http') #could be url string
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
          raise ArgumentError, "Invalid Parse::File initialization with name '#{@name}'"
        end

        @mime_type ||= mime_type

      end

      # This creates a new Parse File Object with from a URL, saves it and returns it
      # @param url [String] A url which will be used to create the file and automatically save it.
      # @return [Parse::File] A newly saved file based on contents of _url_
      def self.create(url)
        url = url.url if url.is_a?(Parse::File)
        file = self.new(url)
        file.save
        file
      end

      # A File object is considered saved if the basename of the URL and the name parameters are equal
      # @return [Boolean] true if this file has already been saved.
      def saved?
        @url.present? && @name.present? && @name == File.basename(@url)
      end

      # Returns the url string for this Parse::File pointer. If the *force_ssl* option is
      # set to true, it will make sure it returns a secure url.
      # @return [String] the url string for the file.
      def url
        if @url.present? && Parse::File.force_ssl && @url.starts_with?('http://')
          return @url.sub('http://', 'https://')
        end
        @url
      end

      # @return [Hash]
      def attributes
        ATTRIBUTES
      end

      # @return [Boolean] Two files are equal if they have the same url
      def ==(u)
        return false unless u.is_a?(self.class)
        @url == u.url
      end

      # Allows mass assignment from a Parse JSON hash.
      def attributes=(h)
        if h.is_a?(String)
          @url = h
          @name = File.basename(h)
        elsif h.is_a?(Hash)
          @url = h[FIELD_URL] || h[:url] || @url
          @name = h[FIELD_NAME] || h[:name] || @name
        end
      end

      # A proxy method for ::File.basename
      # @param file_name [String]
      # @param suffix [String]
      # @return [String] File.basename(file_name)
      # @see ::File.basename
      def self.basename(file_name, suffix = nil)
       if suffix.nil?
         ::File.basename(file_name)
       else
         ::File.basename(file_name, suffix)
       end
      end

      # Save the file by uploading it to Parse and creating a file pointer.
      # @return [Boolean] true if successfully uploaded and saved.
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

      # @return [Boolean] true if this file is hosted by Parse's servers.
      def parse_hosted_file?
        return false if @url.blank?
        ::File.basename(@url).starts_with?('tfss-') || @url.starts_with?('http://files.parsetfss.com')
      end

      # @!visibility private
      def inspect
        "<Parse::File @name='#{@name}' @mime_type='#{@mime_type}' @contents=#{@contents.nil?} @url='#{@url}'>"
      end

      # @return [String] the url
      # @see #url
      def to_s
        @url
      end

    end

end

# Adds extensions to Hash class.
class Hash
  # Determines if the hash contains Parse File json metadata fields. This is determined whether
  # the key `__type` exists and is of type `__File` and whether the `name` field matches the File.basename
  # of the `url` field.
  #
  # @return [Boolean] True if this hash contains Parse file metadata.
  def parse_file?
    url = self[Parse::File::FIELD_URL]
    name = self[Parse::File::FIELD_NAME]
    (count == 2 || self["__type"] == Parse::File.parse_class) &&
    url.present? && name.present? && name == ::File.basename(url)
  end
end
