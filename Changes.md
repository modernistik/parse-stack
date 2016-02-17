# Parse-Stack Changes

1.0.6
-----------
- Fixes issue when making batch requests with special prefix url.
- Adds Parse::ConnectionError custom exception type.
- You can call locally registered cloud functions with
Parse::Webhooks.run_function(:functionName, params) without going through the
entire Parse API network stack.

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
