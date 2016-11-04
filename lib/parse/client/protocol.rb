# encoding: UTF-8
# frozen_string_literal: true


module Parse
  # Set of Parse protocol constants.
  module Protocol
    # The default server url, based on the hosted Parse platform.
    SERVER_URL        = 'https://api.parse.com/1/'
    # The request header field to send the application Id.
    APP_ID            = 'X-Parse-Application-Id'
    # The request header field to send the REST API key.
    API_KEY           = 'X-Parse-REST-API-Key'
    # The request header field to send the Master key.
    MASTER_KEY        = 'X-Parse-Master-Key'
    # The request header field to send the revocable Session key.
    SESSION_TOKEN     = 'X-Parse-Session-Token'
    # The request header field to request a revocable session token.
    REVOCABLE_SESSION = 'X-Parse-Revocable-Session'
    # The request header field to send the installation id.
    INSTALLATION_ID   = 'Parse-Installation-Id'
    # The request header field to send an email when authenticating with Parse hosted platform.
    EMAIL             = 'X-Parse-Email'
    # The request header field to send the password when authenticating with the Parse hosted platform.
    PASSWORD          = 'X-Parse-Password'
    # The request header field for the Content type.
    CONTENT_TYPE      = 'Content-Type'
    # The default content type format for sending API requests.
    CONTENT_TYPE_FORMAT = 'application/json; charset=utf-8'
  end

  # All Parse error codes.
  # @todo Implement all error codes as StandardError
  #
  # List of error codes.
  #  OtherCause	-1	Error code indicating that an unknown error or an error unrelated to Parse occurred.
  #  InternalServerError	1	Error code indicating that something has gone wrong with the server. If you get this error code, it is Parse's fault. Please report the bug to https://parse.com/help.
  #  ConnectionFailed	100	Error code indicating the connection to the Parse servers failed.
  #  ObjectNotFound	101	Error code indicating the specified object doesn't exist.
  #  InvalidQuery	102	Error code indicating you tried to query with a datatype that doesn't support it, like exact matching an array or object.
  #  InvalidClassName	103	Error code indicating a missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.
  #  MissingObjectId	104	Error code indicating an unspecified object id.
  #  InvalidKeyName	105	Error code indicating an invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.
  #  InvalidPointer	106	Error code indicating a malformed pointer. You should not see this unless you have been mucking about changing internal Parse code.
  #  InvalidJSON	107	Error code indicating that badly formed JSON was received upstream. This either indicates you have done something unusual with modifying how things encode to JSON, or the network is failing badly.
  #  CommandUnavailable	108	Error code indicating that the feature you tried to access is only available internally for testing purposes.
  #  NotInitialized	109	You must call Parse.initialize before using the Parse library.
  #  IncorrectType	111	Error code indicating that a field was set to an inconsistent type.
  #  InvalidChannelName	112	Error code indicating an invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter.
  #  PushMisconfigured	115	Error code indicating that push is misconfigured.
  #  ObjectTooLarge	116	Error code indicating that the object is too large.
  #  OperationForbidden	119	Error code indicating that the operation isn't allowed for clients.
  #  CacheMiss	120	Error code indicating the result was not found in the cache.
  #  InvalidNestedKey	121	Error code indicating that an invalid key was used in a nested JSONObject.
  #  InvalidFileName	122	Error code indicating that an invalid filename was used for ParseFile. A valid file name contains only a-zA-Z0-9_. characters and is between 1 and 128 characters.
  #  InvalidACL	123	Error code indicating an invalid ACL was provided.
  #  Timeout	124	Error code indicating that the request timed out on the server. Typically this indicates that the request is too expensive to run.
  #  InvalidEmailAddress	125	Error code indicating that the email address was invalid.
  #  DuplicateValue	137	Error code indicating that a unique field was given a value that is already taken.
  #  InvalidRoleName	139	Error code indicating that a role's name is invalid.
  #  ExceededQuota	140	Error code indicating that an application quota was exceeded. Upgrade to resolve.
  #  ScriptFailed	141	Error code indicating that a Cloud Code script failed.
  #  ValidationFailed	142	Error code indicating that a Cloud Code validation failed.
  #  FileDeleteFailed	153	Error code indicating that deleting a file failed.
  #  RequestLimitExceeded	155	Error code indicating that the application has exceeded its request limit.
  #  InvalidEventName	160	Error code indicating that the provided event name is invalid.
  #  UsernameMissing	200	Error code indicating that the username is missing or empty.
  #  PasswordMissing	201	Error code indicating that the password is missing or empty.
  #  UsernameTaken	202	Error code indicating that the username has already been taken.
  #  EmailTaken	203	Error code indicating that the email has already been taken.
  #  EmailMissing	204	Error code indicating that the email is missing, but must be specified.
  #  EmailNotFound	205	Error code indicating that a user with the specified email was not found.
  #  SessionMissing	206	Error code indicating that a user object without a valid session could not be altered.
  #  MustCreateUserThroughSignup	207	Error code indicating that a user can only be created through signup.
  #  AccountAlreadyLinked	208	Error code indicating that an an account being linked is already linked to another user.
  #  InvalidSessionToken	209	Error code indicating that the current session token is invalid.
  #  LinkedIdMissing	250	Error code indicating that a user cannot be linked to an account because that account's id could not be found.
  #  InvalidLinkedSession	251	Error code indicating that a user with a linked (e.g. Facebook) account has an invalid session.
  #  UnsupportedService	252	Error code indicating that a service being linked (e.g. Facebook or Twitter) is unsupported.
  module ErrorCodes

  end

end
