# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'

module Parse
  # This class represents the data and columns contained in the standard Parse
  # `_Installation` collection. This class is also responsible for managing the
  # device tokens for mobile devices in order to use push notifications. All queries done
  # to send pushes using Parse::Push are performed against the Installation collection.
  # An installation object represents an instance of your app being installed
  # on a device. These objects are used to store subscription data for
  # installations which have subscribed to one or more push notification channels.
  #
  # The default schema for {Installation} is as follows:
  #
  #   class Parse::Installation < Parse::Object
  #      # See Parse::Object for inherited properties...
  #
  #     property :gcm_sender_id, field: :GCMSenderId
  #     property :app_identifier
  #     property :app_name
  #     property :app_version
  #     property :badge, :integer
  #     property :channels, :array
  #     property :device_token
  #     property :device_token_last_modified, :integer
  #     property :device_type, enum: [:ios, :android, :winrt, :winphone, :dotnet]
  #     property :installation_id
  #     property :locale_identifier
  #     property :parse_version
  #     property :push_type
  #     property :time_zone, :timezone
  #
  #     has_one :session, ->{ where(installation_id: i.installation_id) }, scope_only: true
  #   end
  # @see Push
  # @see Parse::Object
  class Installation < Parse::Object

    parse_class Parse::Model::CLASS_INSTALLATION
    # @!attribute gcm_sender_id
    # This field only has meaning for Android installations that use the GCM
    # push type. It is reserved for directing Parse to send pushes to this
    # installation with an alternate GCM sender ID. This field should generally
    # not be set unless you are uploading installation data from another push
    # provider. If you set this field, then you must set the GCM API key
    # corresponding to this GCM sender ID in your Parse application’s push settings.
    # @return [String]
    property :gcm_sender_id, field: :GCMSenderId

    # @!attribute app_identifier
    # A unique identifier for this installation’s client application. In iOS, this is the Bundle Identifier.
    # @return [String]
    property :app_identifier

    # @!attribute app_name
    # The display name of the client application to which this installation belongs.
    # @return [String]
    property :app_name

    # @!attribute app_version
    # The version string of the client application to which this installation belongs.
    # @return [String]
    property :app_version

    # @!attribute badge
    # A number field representing the last known application badge for iOS installations.
    # @return [Integer]
    property :badge, :integer

    # @!attribute channels
    # An array of the channels to which a device is currently subscribed.
    # Note that **channelUris** (the Microsoft-generated push URIs for Windows devices) is
    # not supported at this time.
    # @return [Array]
    property :channels, :array

    # @!attribute device_token
    # The Apple or Google generated token used to deliver messages to the APNs
    # or GCM push networks respectively.
    # @return [String]
    property :device_token

    # @!attribute device_token_last_modified
    # @return [Integer] number of seconds since token modified
    property :device_token_last_modified, :integer

    # @!attribute device_type
    # The type of device, “ios”, “android”, “winrt”, “winphone”, or “dotnet” (readonly).
    # This property is implemented as a Parse::Stack enumeration.
    # @return [String]
    property :device_type, enum: [:ios, :android, :winrt, :winphone, :dotnet]

    # @!attribute installation_id
    # Universally Unique Identifier (UUID) for the device used by Parse. It
    # must be unique across all of an app’s installations. (readonly).
    # @return [String]
    property :installation_id

    # @!attribute locale_identifier
    # The locale for this device.
    # @return [String]
    property :locale_identifier

    # @!attribute parse_version
    # The version of the Parse SDK which this installation uses.
    # @return [String]
    property :parse_version

    # @!attribute push_type
    # This field is reserved for directing Parse to the push delivery network
    # to be used. If the device is registered to receive pushes via GCM, this
    # field will be marked “gcm”. If this device is not using GCM, and is
    # using Parse’s push notification service, it will be blank (readonly).
    # @return [String]
    property :push_type

    # @!attribute time_zone
    # The current time zone where the target device is located. This should be an IANA time zone identifier
    # or a {Parse::TimeZone} instance.
    # @return [Parse::TimeZone]
    property :time_zone, :timezone

    # @!attribute session
    # Returns the corresponding {Parse::Session} associated with this installation, if any exists.
    # This is implemented as a has_one association to the Session class using the {installation_id}.
    # @version 1.7.1
    # @return [Parse::Session] The associated {Parse::Session} that might be tied to this installation
    has_one :session, ->{ where(installation_id: i.installation_id) }, scope_only: true
  end

end
