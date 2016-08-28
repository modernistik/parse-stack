# Parse-Stack Changes

1.4.0
-----------
- NEW: Support for rails generators: `parse_stack:install` and `parse_stack:model`.
- Support for calling `before_save` and `before_destroy` callbacks in your model when a Parse::Object is returned by your `before_save` or `before_delete` webhook respectively.
- Parse::Query `:cache` expression now allows integer values to define the specific cache duration for this specific query request. If `false` is passed, will ignore the cache and make the request regardless if a cache response is available. If `true` is passed (default), it will use the value configured when setting up when calling `Parse.setup`.
- Fixes the use of `:use_master_key` in Parse::Query.
- Fixes to the cache key used in middleware.

1.3.8
-----------
- Support for reloading the Parse config data with `Parse.config!`.
- The Parse::Request object is now provided in the Parse::Response instance.
- The HTTP status code is provided in `http_status` accessor for a Parse::Response.
- Raised errors now provide info on the request that failed.
- Added new `ServiceUnavailableError` exception for Parse error code 2 and HTTP 503 errors.
- Upon a `ServiceUnavailableError`, we will retry the request one more time after 2 seconds.
- `:not_in` and `:contains_all` queries will format scalar values into an array.
- `:exists` and `:null` will raise `ParseConstraintError` if non-boolean values are passed.
- NEW: `:id` constraint to allow passing an objectId to a query where we will infer the class.

1.3.7
-----------
- Fixes json_api loading issue between ruby json and active_model_serializers.
- Fixes loading active_support core extensions.
- Support for passing a `:session_token` as part of a Parse::Query.
- Default mime-type for Parse::File instances is `image/jpeg`. You can override the default by setting
`Parse::File.default_mime_type`.
- Added `Parse.config` for easy access to `Parse::Client.session(:default).config`
- Support for `Parse.auto_upgrade!` to easily upgrade all schemas.
- You can import useful rake tasks by requiring `parse/stack/tasks` in your rake file.
- Changes the format in `select` and `reject` queries (see documentation).
- Latitude and longitude values are now validated with warnings. Will raise exceptions in the future.
- Additional alias methods for queries.
- Added `$within` => `$box` GeoPoint query. (see documentation)
- Improves support when using Parse-Server.
- Major documentation updates.
- `limit` no longer defaults to 100 in `Parse::Query`. This will allow Parse-Server to determine default limit, if any.
- `:bool` property type has been added as an alias to `:boolean`.
- You can turn off formatting field names with `Parse::Query.field_formatter = nil`.

1.3.1
-----------
- Parse::Query now supports `:cache` and `:use_master_key` option. (experimental)
- Minimum ruby version set to 1.9.3 (same as ActiveModel 4.2.1)
- Support for Rails 5.0+ and Rack 2.0+

1.3.0
-----------
- **IMPORTANT**: __Raising an error no longer sends an error response back to
the client in a Webhook trigger. You must now call `error!('...')` instead of
calling `raise '...'`.__ The webhook block is now binded to the Parse::Payload
instance, removing the need to pass `payload` object; use the instance methods directly.
See updated README.md for more details.
- **Parse-Stack will throw new exceptions** depending on the error code returned by Parse. These
are of type AuthenticationError, TimeoutError, ProtocolError, ServerError, ConnectionError and RequestLimitExceededError.
- `nil` and Delete operations for `:integers` and `:booleans` are no longer typecast.
- Added aliases `before`, `on_or_before`, `after` and `on_or_after` to help with
comparing non-integer fields such as dates. These map to `lt`,`lte`, `gt` and `gte`.
- Schema API return true is no changes were made to the table on `auto_upgrade!` (success)
- Parse::Middleware::Caching no longer caches 404 and 410 responses; and responses
with content lengths less than 20 bytes.
- FIX: Parse::Payload when applying auth_data in Webhooks. This fixes handing Facebook
login with Android devices.
- New method `save!` to raise an exception if the save fails.
- FIX: Verify Content-Type header field is present for webhooks before checking its value.
- FIX: Support `reload!` when using it Padrino.

1.2.1
-----------
- Add active support string dependencies.
- Support for handling the `Delete` operation on belongs_to
  and has_many relationships.
- Documentation changes for supported Parse atomic operations.

1.2
-----------
- Fixes issues with first_or_create.
- Fixes issue when singularizing :belongs_to and :has_many property names.
- Makes sure time is sent as UTC in queries.
- Allows for authData to be applied as an update to a before_save for a Parse::User.
- Webhooks allow for returning empty data sets and `false` from webhook functions.
- Minimum version for ActiveModel and ActiveSupport is now 4.2.1

1.1
-----------
- In Query `join` has been renamed to `matches`.
- Not In Query `exclude` has been renamed to `excludes` for consistency.
- Parse::Query now has a `:keys` operation to be usd when passing sub-queries to `select` and `matches`
- Improves query supporting `select`, `matches`, `matches` and `excludes`.
- Regular expression queries for `like` now send regex options

1.0.10
-----------
- Fixes issues with setting default values as dirty when using the builder or before_save hook.
- Fixes issues with autofetching pointers when default values are set.

1.0.8
-----------
- Fixes issues when setting a collection proxy property with a collection proxy.
- Default array values are now properly casted as collection proxies.
- Default booleans values of `false` are now properly set.

1.0.7
-----------
- Fixes issues when copying dates.
- Fixes issues with double-arrays.
- Fixes issues with mapping columns to atomic operations.

1.0.6
-----------
- Fixes issue when making batch requests with special prefix url.
- Adds Parse::ConnectionError custom exception type.
- You can call locally registered cloud functions with
Parse::Webhooks.run_function(:functionName, params) without going through the
entire Parse API network stack.
- `:symbolize => true` now works for `:array` data types. All items in the collection
will be symbolized - useful for array of strings.
- Prevent ACLs from causing an autofetch.
- Empty strings, arrays and `false` are now working with `:default` option in properties.

1.0.5
-----------
- Defaults are applied on object instantiation.
- When applying default values, dirty tracking is called.

1.0.4
-----------
- Fixes minor issue when storing and retrieving objects from the cache.
- Support for providing :server_url as a connection option for those migrating hosting
  their own parse-server.

1.0.3
-----------
- Fixes minor issue when passing `nil` to the class `find` method.

1.0.2
-----------
- Fixes internal issue with `operate_field!` method.

1.0.1
-----------
- Initial RubyGems release.
