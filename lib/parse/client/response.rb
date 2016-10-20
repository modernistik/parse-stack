# encoding: UTF-8
# frozen_string_literal: true

# Member name	Value	Description
# OtherCause	-1	Error code indicating that an unknown error or an error unrelated to Parse occurred.
# InternalServerError	1	Error code indicating that something has gone wrong with the server. If you get this error code, it is Parse's fault. Please report the bug to https://parse.com/help.
# ConnectionFailed	100	Error code indicating the connection to the Parse servers failed.
# ObjectNotFound	101	Error code indicating the specified object doesn't exist.
# InvalidQuery	102	Error code indicating you tried to query with a datatype that doesn't support it, like exact matching an array or object.
# InvalidClassName	103	Error code indicating a missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.
# MissingObjectId	104	Error code indicating an unspecified object id.
# InvalidKeyName	105	Error code indicating an invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.
# InvalidPointer	106	Error code indicating a malformed pointer. You should not see this unless you have been mucking about changing internal Parse code.
# InvalidJSON	107	Error code indicating that badly formed JSON was received upstream. This either indicates you have done something unusual with modifying how things encode to JSON, or the network is failing badly.
# CommandUnavailable	108	Error code indicating that the feature you tried to access is only available internally for testing purposes.
# NotInitialized	109	You must call Parse.initialize before using the Parse library.
# IncorrectType	111	Error code indicating that a field was set to an inconsistent type.
# InvalidChannelName	112	Error code indicating an invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter.
# PushMisconfigured	115	Error code indicating that push is misconfigured.
# ObjectTooLarge	116	Error code indicating that the object is too large.
# OperationForbidden	119	Error code indicating that the operation isn't allowed for clients.
# CacheMiss	120	Error code indicating the result was not found in the cache.
# InvalidNestedKey	121	Error code indicating that an invalid key was used in a nested JSONObject.
# InvalidFileName	122	Error code indicating that an invalid filename was used for ParseFile. A valid file name contains only a-zA-Z0-9_. characters and is between 1 and 128 characters.
# InvalidACL	123	Error code indicating an invalid ACL was provided.
# Timeout	124	Error code indicating that the request timed out on the server. Typically this indicates that the request is too expensive to run.
# InvalidEmailAddress	125	Error code indicating that the email address was invalid.
# DuplicateValue	137	Error code indicating that a unique field was given a value that is already taken.
# InvalidRoleName	139	Error code indicating that a role's name is invalid.
# ExceededQuota	140	Error code indicating that an application quota was exceeded. Upgrade to resolve.
# ScriptFailed	141	Error code indicating that a Cloud Code script failed.
# ValidationFailed	142	Error code indicating that a Cloud Code validation failed.
# FileDeleteFailed	153	Error code indicating that deleting a file failed.
# RequestLimitExceeded	155	Error code indicating that the application has exceeded its request limit.
# InvalidEventName	160	Error code indicating that the provided event name is invalid.
# UsernameMissing	200	Error code indicating that the username is missing or empty.
# PasswordMissing	201	Error code indicating that the password is missing or empty.
# UsernameTaken	202	Error code indicating that the username has already been taken.
# EmailTaken	203	Error code indicating that the email has already been taken.
# EmailMissing	204	Error code indicating that the email is missing, but must be specified.
# EmailNotFound	205	Error code indicating that a user with the specified email was not found.
# SessionMissing	206	Error code indicating that a user object without a valid session could not be altered.
# MustCreateUserThroughSignup	207	Error code indicating that a user can only be created through signup.
# AccountAlreadyLinked	208	Error code indicating that an an account being linked is already linked to another user.
# InvalidSessionToken	209	Error code indicating that the current session token is invalid.
# LinkedIdMissing	250	Error code indicating that a user cannot be linked to an account because that account's id could not be found.
# InvalidLinkedSession	251	Error code indicating that a user with a linked (e.g. Facebook) account has an invalid session.
# UnsupportedService	252	Error code indicating that a service being linked (e.g. Facebook or Twitter) is unsupported.

require 'active_support'
require 'active_support/json'
# This is the model that represents a response from Parse. A Response can also
# be a set of responses (from a Batch response).
module Parse

  class ResponseError < StandardError; end;
  class Response
    include Enumerable

    ERROR_INTERNAL = 1
    ERROR_SERVICE_UNAVAILALBE = 2
    ERROR_TIMEOUT = 124
    ERROR_EXCEEDED_BURST_LIMIT = 155
    ERROR_OBJECT_NOT_FOUND = 101
    ERROR_USERNAME_MISSING = 200
    ERROR_PASSWORD_MISSING = 201
    ERROR_USERNAME_TAKEN = 202
    ERROR_EMAIL_TAKEN = 203
    ERROR_EMAIL_NOT_FOUND = 205
    ERROR_EMAIL_INVALID = 125

    ERROR = "error"
    CODE = "code"
    RESULTS = "results"
    COUNT = "count"
    # A response has a result or (a code and an error)
    attr_accessor :parse_class, :code, :error, :result, :http_status
    attr_accessor :request # capture request that created result
    # You can query Parse for counting objects, which may not actually have
    # results.
    attr_reader :count

    def initialize(res = {})
      @http_status = 0
      @count = 0
      @batch_response = false # by default, not a batch response
      @result = nil
      # If a string is used for initializing, treat it as JSON
      res = JSON.parse(res) if res.is_a?(String)
      # If it is a hash (or parsed JSON), then parse the result.
      parse_result(res) if res.is_a?(Hash)
      # if the result is an Array, then most likely it is a set of responses
      # from using a Batch API.
      if res.is_a?(Array)
        @batch_response = true
        @result = res || []
        @count = @result.count
      end
      #if none match, set pure result
      @result = res if @result.nil?

    end

    def batch?
      @batch_response
    end
    #batch response
    #
    # [
    #   {
    #     "success":{"createdAt":"2015-11-22T19:04:16.104Z","objectId":"s4tEzOVQFc"}
    #   },
    #  {
    #  "error":{"code":101,"error":"object not found for update"}
    #  }
    # ]
    # If it is a batch respnose, we'll create an array of Response objects for each
    # of the ones in the batch.
    def batch_responses

      return [@result] unless @batch_response
      # if batch response, generate array based on the response hash.
      @result.map do |r|
        next r unless r.is_a?(Hash)
        hash = r["success"] || r[ERROR]
        Parse::Response.new hash
      end
    end

    # This method takes the result hash and determines if it is a regular
    # parse query result, object result or a count result. The response should
    # be a hash either containing the result data or the error.

    def parse_result(h)
      @result = {}
      return unless h.is_a?(Hash)
      @code = h[CODE]
      @error = h[ERROR]
      if h[RESULTS].is_a?(Array)
        @result = h[RESULTS]
        @count = h[COUNT] || @result.count
      else
        @result = h
        @count = 1
      end

    end

    # determines if the response is successful.
    def success?
      @code.nil? && @error.nil?
    end

    def error?
      ! success?
    end

    def object_not_found?
      @code == ERROR_OBJECT_NOT_FOUND
    end

    # returns the result data from the response. Always returns an array.
    def results
      return [] if @result.nil?
      @result.is_a?(Array) ? @result : [@result]
    end

    # returns the first thing in the array.
    def first
      @result.is_a?(Array) ? @result.first : @result
    end

    def each
      return enum_for(:each) unless block_given?
      results.each(&Proc.new)
      self
    end

    def inspect
      if error?
        "#<#{self.class} @code=#{code} @error='#{error}'>"
      else
        "#<#{self.class} @result='#{@result}'>"
      end
    end

    def to_s
      return "[E-#{@code}] #{@request} : #{@error} (#{@http_status})" if error?
      @result.to_json
    end

  end
end
