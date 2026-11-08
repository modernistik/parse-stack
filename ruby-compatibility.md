# Ruby compatibility and modernization findings

Recorded: 2026-11-07. See the [findings index](compatibility-findings.md) and [validation evidence](compatibility-validation.md).

## Target and scope

The requested minimum is **Ruby 3.0**, including later Ruby versions. An initial minimum of 3.3 was corrected before this report. The final gemspec requires `>= 3.0`.

Supporting Ruby 3.0 requires compatible dependencies and development tooling. Changing only `required_ruby_version` would not have been sufficient.

Sources: [gemspec](parse-stack.gemspec), [Gemfile](Gemfile), [lockfile](Gemfile.lock), [CI workflow](.github/workflows/ruby.yml).

## Initial findings and fixes

| Finding | Effect | Implemented change | Main sources |
| --- | --- | --- | --- |
| 26 implicit `Proc.new` capture sites across nine library files | Block-based setup, iteration, batching, and webhooks can raise on Ruby 3. | Capture blocks explicitly and forward them. No executable implicit-capture sites remain. | [client](lib/parse/client.rb), [query](lib/parse/query.rb), [batch](lib/parse/client/batch.rb), [response](lib/parse/client/response.rb), [collections](lib/parse/model/associations/collection_proxy.rb), [webhooks](lib/parse/webhooks.rb) |
| Option hashes passed positionally to keyword-argument methods | Queries, fetching, authentication, and session calls can fail before HTTP. | Forward request options with `**opts` or `**_opts`. | [query](lib/parse/query.rb), [fetching](lib/parse/model/core/fetching.rb), [users API](lib/parse/api/users.rb), [user model](lib/parse/model/classes/user.rb), [session model](lib/parse/model/classes/session.rb) |
| Scope and association delegation did not preserve keywords | Keyword-based lambdas and chained methods can receive the wrong arguments. | Preserve positional arguments, keywords, and blocks separately. | [querying](lib/parse/model/core/querying.rb), [has-many](lib/parse/model/associations/has_many.rb), [has-one](lib/parse/model/associations/has_one.rb), [time zone](lib/parse/model/time_zone.rb) |
| `open(url)` used for remote content | Modern Ruby treats the URL as a local filename. | Use `URI.open`; parse remote JSON explicitly. | [file model](lib/parse/model/file.rb), [configuration](lib/parse/stack.rb), [console](bin/parse-console) |
| `File.exists?` used by the console | The alias is unavailable on newer Ruby versions. | Use `File.exist?`. | [console](bin/parse-console) |
| Faraday 0.x dependency and old exception namespace | Prevents using the updated HTTP dependency safely. | Migrate to Faraday 2 and its current error namespace. | [client](lib/parse/client.rb), [gemspec](parse-stack.gemspec) |
| Unused separate serializer dependency | Pulls in Rails components that the SDK does not need. | Remove `active_model_serializers`; use ActiveModel's built-in JSON serialization. | [model](lib/parse/model/model.rb), [gemspec](parse-stack.gemspec) |
| Setup mutated caller options and overrode a block-selected adapter | Frozen configuration hashes fail; custom adapter selection is lost. | Copy options, merge nested Faraday options into a new hash, and apply the default adapter before the caller's block. | [client](lib/parse/client.rb), `initialize` |
| Explicit request submission used positional arguments | `send_request` could not call the keyword-based request interface correctly. | Forward the request object and its options. | [client](lib/parse/client.rb), `send_request` |
| Query-scoped `save_all` called the model method twice when given a block | Could perform a second save operation. | Delegate once with the captured block. | [actions](lib/parse/model/core/actions.rb) |
| Pointer constraints mutated input strings with `strip!` | Frozen object IDs raise; caller-owned strings are modified. | Use non-mutating `strip`. | [constraints](lib/parse/query/constraints.rb) |
| URL-backed file loading did not bound the stream lifetime | Downloaded streams were not explicitly closed by the SDK's code path. | Read through the block form of `URI.open`. | [file model](lib/parse/model/file.rb) |
| Webhooks assumed a rewindable request body | A valid non-rewindable Rack input may lack `rewind`. | Check for `rewind` before calling it. The case where an object exposes `rewind` but raises on seeking was not separately tested. | [webhooks](lib/parse/webhooks.rb) |
| Development server used Rack server/handler classes | Rack 3 moves server tooling into Rackup. | Use `Rackup::Server` with Puma. | [server](bin/server), [Gemfile](Gemfile) |
| Test helpers used the old `MiniTest` namespace | The custom `refute_raises` helper was unavailable with the updated Minitest. | Use `Minitest`; require the mock/stub support explicitly. | [test helper](test/test_helper.rb) |
| `distinct` retained one positional options call after the initial migration | Ruby 3 raised before sending the aggregate request. | Forward `**_opts` and add a request regression test. | [query](lib/parse/query.rb), [client test](test/lib/parse/client_test.rb) |

## Final dependency decisions

| Dependency | Final requirement or choice | Reason |
| --- | --- | --- |
| Ruby | `>= 3.0` | Requested minimum. |
| ActiveModel / ActiveSupport | `>= 7.1`, `< 9` | Allows a Ruby 3.0-compatible 7.1 release and newer releases on newer Rubies. |
| JSON | `>= 2.7`, `< 3` | The locked ActiveSupport 7.1.4.2 passes `quirks_mode`; JSON 3 rejects that option. This failed in actual Ruby 3.0 tests before the limit was added. |
| Faraday | `~> 2.0` | Updated HTTP client implementation. |
| Faraday Net::HTTP adapter | `>= 3`, `< 4` | Explicit default adapter dependency. |
| Rack | `>= 3.1`, `< 4` | Updated webhook interface. |
| Bundler | Development lockfile: `2.5.23` | Bundler 4 excludes Ruby 3.0. Bundler 2.5.23 supports the requested minimum. This is a development-tool choice, not a runtime gem dependency. |
| Minitest | `~> 5.25` | Keep compatible test APIs while allowing Ruby-aware dependency resolution. The Ruby 3.0 lockfile resolves Minitest 5.26.1. |
| Standard-library gems | Explicit requirements in the gemspec | Libraries formerly available by default must be declared on newer Rubies. |

Explicit standard-library dependencies are `base64`, `benchmark`, `bigdecimal`, `date`, `irb`, `json`, `logger`, `open-uri`, `optparse`, `ostruct`, `securerandom`, and `time`. In particular, the older ActiveSupport branch needed explicit `benchmark` support when run on Ruby 4.

The shared development lockfile was resolved using Ruby 3.0. It uses ActiveModel/ActiveSupport 7.1.4.2 and JSON 2.21.2. A separate [Gemfile](gemfiles/latest.gemfile) exercises ActiveModel 8.1 on newer Rubies. These are development test configurations; an application's own Bundler resolution can select another version inside the gemspec's allowed range.

## CI findings and changes

The original GitHub workflow listed Ruby 2.5, 2.6, and 2.7. A separate Travis configuration listed 3.1.2, but that was not evidence of a passing current workflow.

The updated [GitHub workflow](.github/workflows/ruby.yml) configures:

- Ruby 3.0, 3.1, 3.2, 3.3, 3.4, and 4.0 with the shared lockfile.
- Ubuntu 24.04 and macOS 15 runners.
- Separate ActiveModel 8.1 jobs on Ruby 3.4 and 4.0.
- Disposable Parse Server 9.10.7/MongoDB 8.0.17 jobs on Ruby 3.0 and 4.0.
- Bundler caching and the test task.

The [Travis configuration](.travis.yml) also lists the expanded Ruby range and installs Bundler 2.5.23. Remote workflow execution has not been verified.

## Migration impact

- Ruby 2.x is outside the new supported range.
- Applications with custom Faraday middleware/adapters must review Faraday 2 compatibility.
- Webhook hosting must use Rack 3-compatible tooling. `bin/server` now uses Rackup/Puma.
- Applications that directly use `active_model_serializers` must declare that dependency themselves.
- Development debugging uses `debug`; obsolete Pry extensions and Thin were removed from the development Gemfile.
- The public API was preserved where practical, but the new minimum Ruby and dependency majors are release-level compatibility changes.

## Verification limits

See [validation evidence](compatibility-validation.md) for exact results. Local suite success covers Ruby behavior and selected controlled HTTP/Rack interactions. It does not establish complete REST API compliance, database behavior, or compatibility with every allowed dependency combination.

Ruby 3.0 and 3.2 test runtimes were built in temporary directories. Ruby 3.0 needed compiler-compatibility adjustments and a rebuilt socket extension on this Mac. Those adjustments affect only the temporary interpreter, not this SDK. The user's existing Ruby installations were not repaired or replaced.
