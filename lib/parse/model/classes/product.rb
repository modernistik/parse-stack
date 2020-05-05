# encoding: UTF-8
# frozen_string_literal: true
require_relative "../object"
require_relative "user"

module Parse
  # This class represents the data and columns contained in the standard Parse `_Product` collection.
  # These records are usually used when implementing in-app purchases in mobile applications.
  #
  # The default schema for {Product} is as follows:
  #
  #   class Parse::Product < Parse::Object
  #      # See Parse::Object for inherited properties...
  #
  #      property :download, :file
  #      property :icon,     :file,    required: true
  #      property :order,    :integer, required: true
  #      property :subtitle,           required: true
  #      property :title,              required: true
  #      property :product_identifier, required: true
  #
  #   end
  # @see Parse::Object
  class Product < Parse::Object
    parse_class Parse::Model::CLASS_PRODUCT
    # @!attribute download
    # @return [String] the file payload for this product download.
    property :download, :file

    # @!attribute download_name
    # @return [String] the name of this download.
    property :download_name

    # @!attribute icon
    # An icon file representing this download. This field is required by Parse.
    # @return [String]
    property :icon, :file, required: true

    # @!attribute order
    # The product order number. This field is required by Parse.
    # @return [String]
    property :order, :integer, required: true

    # @!attribute product_identifier
    # The product identifier. This field is required by Parse.
    # @return [String]
    property :product_identifier, required: true

    # @!attribute subtitle
    # The subtitle description for this product. This field is required by Parse.
    # @return [String]
    property :subtitle, required: true

    # @!attribute title
    # The title for this product. This field is required by Parse.
    # @return [String] the title for this product.
    property :title, required: true
  end
end
