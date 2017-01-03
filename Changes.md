## Parse-Stack Changelog

### 1.6.6
- Default SERVER_URL changed to http://localhost:1337/parse
- NEW: Command line tool `parse-console` to do interactive Parse development with parse-stack.

### 1.6.5
- Client handles HTTP Status 429 (RetryLimitExceeded)
- Role class does not automatically set default ACLs for Roles. You can restore
previous behavior by using `before_save :apply_default_acls`.
- Fixed minor issue to Parse::User.signup when merging username into response.
- NEW: Adds Parse::Product core class.
- NEW: Rake task to list registered webhooks. `rake parse:webhooks:list`
- Experimental support for beforeFind and afterFind - though webhook support not
yet fully available in open source Parse Server.
- Removes HTTPS requirement on webhooks.
- FIXES: Issue with WEBHOOK_KEY not being properly validated when set.
- beforeSaves now return empty hash instead of true on noop changes.

### 1.6.4
- Fixes #20: All temporary headers values are strings.
- Reduced cache storage consumption by only storing response body and headers.
- Increased maximum cache content length size to 1.25 MB.
- You may pass a redis url to the :cache option of setup.
- Fixes issue with invalid struct size of Faraday::Env with old caching keys.
- Added server_info and health check APIs for Parse-Server +2.2.25.
- Updated test to validate against MT6.

### 1.6.1
- NEW: Batch requests are now parallelized.
- `skip` in queries no longer capped to 10,000.
- `limit`  in queries no longer capped at 1000.
- `all()` queries can now return as many results as possible.
- NEW: `each()` method on Parse::Object subclasses to iterate
  over all records in the colleciton.

### 1.6.0
- NEW: Auto generate models based on your remote schema.
- The default server url is now 'http://localhost:1337/parse'.
- Improves thread-safety of Webhooks middleware.
- Performance improvements.
- BeforeSave change payloads do not include the className field.
- Reaches 100% documentation (will try to keep it up).
- Retry mechanism now configurable per client through `retry_limit`.
- Retry now follows sampling back-off delay algorithm.
- Adds `schemas` API to retrieve all schemas for an application.
- :number can now be used as an alias for the :integer data type.
- :geo_point can now be used as an alias for the :geopoint data type.
- Support accessing properties of Parse::Object subclasses through the [] operator.
- Support setting properties of Parse::Object subclasses through the []= operator.
- :to_s method of Parse::Date returns the iso8601(3) by default, if no arguments are provided.
- Parse::ConstraintError has been removed in favor of ArgumentError.
- Parse::Payload has been placed under Parse::Webhooks::Payload for clarity.
- Parse::WebhookErrorResponse has been moved to Parse::Webhooks::ResponseError.
- Moves Parse::Object modular functionality under Core namespace
- Renames ClassBuilder to Parse::Model::Builder
- Renamed SaveFailureError to RecordNotSaved for ActiveRecord similarity.
- All Parse errors inherit from Parse::Error.

### 1.5.3
- Several fixes and performance improvements.
- Major revisions to documentation.
- Support for increment! and decrement! for Integer and Float properties.

### 1.5.2
- FIXES #16: Constraints to `count` were not properly handled.
- FIXES #15: Incorrect call to `request_password_reset`.
- FIXES #14: Typos
- FIXES: Issues when passing a block to chaining scope.
- FIXES: Enums properly handle default values.
- FIXES: Enums macro methods now are dirty tracked.
- FIXES: #17: overloads inspect to show objects in a has_many scope.
- `reload!` and session methods support client request options.
- Proactively deletes possible matching cache keys on non GET requests.
- Parse::File now has a `force_ssl` option that makes sure all urls returned are `https`.
- Documentation
- ParseConstraintError is now Parse::ConstraintError.
- All constraint subclasses are under the Constraint namespace.

### 1.5.1
- BREAKING CHANGE: The default `has_many` implementation is `:query` instead of `:array`.
- NEW: Support for `has_one` type of associations.
- NEW: `has_many` associations support `Query` implementation as the inverse of `:belongs_to`.
- NEW: `has_many` and `has_one` associations support scopes as second parameter.
- NEW: Enumerated property types that mimic ActiveRecord::Enum behavior.
- NEW: Support for scoped queries similar to ActiveRecord::Scope.
- NEW: Support updating Parse config using `set_config` and `update_config`
- NEW: Support for user login, logout and sessions.
- NEW: Support for signup, including signing up with third-party services.
- NEW: Support for linking and unlinking user accounts with third-party services.
- NEW: Improved support for Parse session APIs.
- NEW: Boolean properties automatically generate a positive query scope for the field.
- Added property options for `:scopes`, `:enum`, `:_prefix` and `:_suffix`
- FIX: Auto-upgrade did not upgrade core classes.
- FIX: Pointer and Relation collection proxies will delay pointer casting until update.
- Improves JSON encoding/decoding performance.
- Removes throttling of requests.
- Turns off cache when using `save_all` method.
- Parse::Query supports ActiveModel::Callbacks for `:prepare`.
- Subclasses now support a :create callback that is only executed after a new object is successfully saved.
- Added alias method :execute! for Parse::Query#fetch! for clarity.
- `Parse::Client.session` has been deprecated in favor of `Parse::Client.client`
- All Parse-Stack errors that are raised inherit from StandardError.
- All :object data types is now cast as ActiveSupport::HashWithIndifferentAccess.
- :boolean properties now have a special `?` method to access true/false values.
- Adds chaining to Parse::Query#conditions.
- Adds alias instance method `Parse::Query#query` to `Parse::Query#conditions`.
- `Parse::Object.where` is now an alias to `Parse::Object.query`. You can now use `Parse::Object.where_literal`.
- Parse::Query and Parse::CollectionProxy support Enumerable mixin.
- Parse::Query#constraints allow you to combine constraints from different queries.
- `Parse::Object#validate!` can be used in webhook to throw webhook error on failed validation.

### 1.4.3
- NEW: Support for rails generators: `parse_stack:install` and `parse_stack:model`.
- Support Parse::Date with ActiveSupport::TimeWithZone.
- :date properties will now raise an error if value was not converted to a Parse::Date.
- Support for calling `before_save` and `before_destroy` callbacks in your model when a Parse::Object is returned by your `before_save` or `before_delete` webhook respectively.
- Parse::Query `:cache` expression now allows integer values to define the specific cache duration for this specific query request. If `false` is passed, will ignore the cache and make the request regardless if a cache response is available. If `true` is passed (default), it will use the value configured when setting up when calling `Parse.setup`.
- Fixes the use of `:use_master_key` in Parse::Query.
- Fixes to the cache key used in middleware.
- Parse::User before_save callback clears the record ACLs.
- Added `anonymous?` instance method to `Parse::User` class.

### 1.3.8
- Support for reloading the Parse config data with `Parse.config!`.
- The Parse::Request object is now provided in the Parse::Response instance.
- The HTTP status code is provided in `http_status` accessor for a Parse::Response.
- Raised errors now provide info on the request that failed.
- Added new `ServiceUnavailableError` exception for Parse error code 2 and HTTP 503 errors.
- Upon a `ServiceUnavailableError`, we will retry the request one more time after 2 seconds.
- `:not_in` and `:contains_all` queries will format scalar values into an array.
- `:exists` and `:null` will raise `ConstraintError` if non-boolean values are passed.
- NEW: `:id` constraint to allow passing an objectId to a query where we will infer the class.

### 1.3.7
- Fixes json_api loading issue between ruby json and active_model_serializers.
- Fixes loading active_support core extensions.
- Support for passing a `:session_token` as part of a Parse::Query.
- Default mime-type for Parse::File instances is `image/jpeg`. You can override the default by setting
`Parse::File.default_mime_type`.
- Added `Parse.config` for easy access to `Parse::Client.client(:default).config`
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

### 1.3.1
- Parse::Query now supports `:cache` and `:use_master_key` option. (experimental)
- Minimum ruby version set to 1.9.3 (same as ActiveModel 4.2.1)
- Support for Rails 5.0+ and Rack 2.0+

### 1.3.0
- **IMPORTANT**: __Raising an error no longer sends an error response back to
the client in a Webhook trigger. You must now call `error!('...')` instead of
calling `raise '...'`.__ The webhook block is now binded to the Parse::Webhooks::Payload
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

### 1.2.1
- Add active support string dependencies.
- Support for handling the `Delete` operation on belongs_to
  and has_many relationships.
- Documentation changes for supported Parse atomic operations.

### 1.2
- Fixes issues with first_or_create.
- Fixes issue when singularizing :belongs_to and :has_many property names.
- Makes sure time is sent as UTC in queries.
- Allows for authData to be applied as an update to a before_save for a Parse::User.
- Webhooks allow for returning empty data sets and `false` from webhook functions.
- Minimum version for ActiveModel and ActiveSupport is now 4.2.1

### 1.1
- In Query `join` has been renamed to `matches`.
- Not In Query `exclude` has been renamed to `excludes` for consistency.
- Parse::Query now has a `:keys` operation to be usd when passing sub-queries to `select` and `matches`
- Improves query supporting `select`, `matches`, `matches` and `excludes`.
- Regular expression queries for `like` now send regex options

### 1.0.10
- Fixes issues with setting default values as dirty when using the builder or before_save hook.
- Fixes issues with autofetching pointers when default values are set.

### 1.0.8
- Fixes issues when setting a collection proxy property with a collection proxy.
- Default array values are now properly casted as collection proxies.
- Default booleans values of `false` are now properly set.

### 1.0.7
- Fixes issues when copying dates.
- Fixes issues with double-arrays.
- Fixes issues with mapping columns to atomic operations.

### 1.0.6
- Fixes issue when making batch requests with special prefix url.
- Adds Parse::ConnectionError custom exception type.
- You can call locally registered cloud functions with
Parse::Webhooks.run_function(:functionName, params) without going through the
entire Parse API network stack.
- `:symbolize => true` now works for `:array` data types. All items in the collection
will be symbolized - useful for array of strings.
- Prevent ACLs from causing an autofetch.
- Empty strings, arrays and `false` are now working with `:default` option in properties.

### 1.0.5
- Defaults are applied on object instantiation.
- When applying default values, dirty tracking is called.

### 1.0.4
- Fixes minor issue when storing and retrieving objects from the cache.
- Support for providing :server_url as a connection option for those migrating hosting
  their own parse-server.

### 1.0.3
- Fixes minor issue when passing `nil` to the class `find` method.

### 1.0.2
- Fixes internal issue with `operate_field!` method.
