# Parse-Stack Changes

1.3.0
-----------
- `nil` and Delete operations for `:integers` and `:booleans` are no longer typecast.
- Added aliases `before`, `on_or_before`, `after` and `on_or_after` to help with
comparing non-integer fields such as dates. These map to `lt`,`lte`, `gt` and `gte`.
- Schema API return true is no changes were made to the table on `auto_upgrade!` (success)
- Parse::Middleware::Caching no longer caches 404 and 410 responses; and responses
with content lengths less than 20 bytes.
- Fixes Parse::Payload when applying auth_data in Webhooks. This fixes handing Facebook
login with Android devices.
- New method `save!` to raise an exception if the save fails.
- Parse-Stack will throw new exceptions depending on the error code returned by Parse. These
are of type AuthenticationError, TimeoutError, ProtocolError, ServerError, ConnectionError and RequestLimitExceededError.

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
- Parse::Query now has a `:key` operation to be usd when passing sub-queries to `select` and `matches`
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
