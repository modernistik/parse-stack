# Compatibility validation evidence

Recorded: 2026-11-07. Applies to the working tree. Related: [findings](compatibility-findings.md), [Ruby changes](ruby-compatibility.md), [REST review](rest-api-compatibility.md), [support plan](rest-api-support.md).

## Final unit suite

| Ruby | ActiveModel | Tests | Assertions | Failures / errors / skips |
| --- | --- | ---: | ---: | --- |
| 3.0.7 | Shared lock: 7.1.4.2 | 137 | 875 | 0 / 0 / 0 |
| 3.1 | CI configured; not run locally | — | — | Unverified |
| 3.2.10 | Shared lock: 7.1.4.2 | 137 | 875 | 0 / 0 / 0 |
| 3.3.10 | Shared lock: 7.1.4.2 | 137 | 875 | 0 / 0 / 0 |
| 3.4.1 | Shared lock: 7.1.4.2 | 137 | 875 | 0 / 0 / 0 |
| 4.0.2 | Shared lock: 7.1.4.2 | 137 | 875 | 0 / 0 / 0 |
| 3.4.1 | Newer Gemfile: 8.1.4.1 | 137 | 875 | 0 / 0 / 0 |
| 4.0.2 | Newer Gemfile: 8.1.4.1 | 137 | 875 | 0 / 0 / 0 |

Each completed run: `137 tests, 875 assertions, 0 failures, 0 errors, 0 skips`.

Original suite: 95 tests. Modernization added 27; REST repairs/extensions added 15. Sources: [Ruby tests](test/lib/parse/ruby_compatibility_test.rb), [client tests](test/lib/parse/client_test.rb), [webhooks](test/lib/parse/webhooks_test.rb), [REST contracts](test/lib/parse/rest_api_test.rb).

Added coverage includes block/keyword forwarding, scopes/associations, queries, auth options, explicit requests, dirty tracking, URL files, config, frozen inputs, long-query overrides, connection errors, Rack behavior, headers, empty HTTP 204, installation IDs, jobs, advanced parameters, pipeline encoding, helper routes, and batch sizing.

## Live baseline

| SDK Ruby | Parse Server | MongoDB | Node | Tests | Assertions | Failures / errors / skips |
| --- | --- | --- | --- | ---: | ---: | --- |
| 3.0.7 | 9.10.7 | 8.0.17 | 24.11.0 | 10 | 57 | 0 / 0 / 0 |
| 4.0.2 | 9.10.7 | 8.0.17 | 24.11.0 | 10 | 57 | 0 / 0 / 0 |

Both final commands exited successfully, including cleanup. The first trial passed assertions but exposed a harness shutdown error; the runner was fixed and both final runs passed.

Sources: [runner](test/integration/run.js), [tests](test/integration/rest_api_test.rb), [Cloud Code](test/integration/cloud.js), [pins](test/integration/package.json), [npm lock](test/integration/package-lock.json).

| Case | Verified result |
| --- | --- |
| CRUD/errors | Create/fetch/update/delete; missing object gives HTTP 404 / Parse 101. |
| Types/atomic updates | Date/GeoPoint/Bytes; increment and AddUnique. |
| Queries | Filter/order/count/distinct; top-level preference/exclusion; comma and JSON-array projections. |
| Pipeline | Group and sum return the expected total. |
| Batch | 21 objects saved under the custom mount with configured chunks. |
| Users/sessions | Signup/login, installation in session, current user, impersonation, logout, invalid token. |
| ACL | Public credentials cannot fetch a private object; master credentials can. |
| Files | Binary upload/deletion through an in-memory adapter. |
| Schema | Create, add field, fetch, delete empty class. |
| Cloud | Function result; retained job ID and successful job completion. |

The runner owns random local credentials, a temporary database, and an ephemeral loopback port. It accepts no deployment URL. No production data was accessed. Expected negative cases produce server error logs; these are assertions, not failures.

## Earlier audit evidence

Controlled Faraday probes initially found options inside `where`, the header missing `X-`, nil job tracking despite a successful response, and a distinct positional-argument error. They also captured one 21-operation batch, comma projections, and absent deletion/impersonation helpers. Final contracts/live tests replace these probes as current-state evidence; see the [REST report](rest-api-compatibility.md).

## Other checks

- Earlier Net::HTTP loopback checks passed on Ruby 3.0.7, 3.3.10, 3.4.1, and 4.0.2. Final integration also uses real HTTP.
- Earlier Ruby 3.0 syntax compilation and Ruby 3.4 console-help checks passed. Interactive console connections were not exercised.
- Before the version bump, gem 1.9.1 built and installed-package loads passed outside the checkout on Ruby 3.0.7 and 3.4.1, including the new REST helpers and `>= 3.0` metadata. The Ruby 3.4 check uses Bundler to select compatible installed dependencies. The source version is now 2.0.0; no package was published.
- CI: Ruby 3.0–3.4/4.0 on Linux/macOS; newer dependencies on 3.4/4.0; integration on 3.0/4.0 Ubuntu. Remote execution is unverified.
- `git diff --check` passed.

## Reproduce

### Version 2.0.0 checks

After the version bump, Ruby 3.0.7 and 4.0.2 each passed 137 tests and 875 assertions with no failures, errors, or skips. Gem 2.0.0 built and installed into a temporary directory; an isolated Ruby 3.0.7 load confirmed the gem/library version, `>= 3.0` requirement, `Parse-Stack v2.0.0` user agent, and packaged support documentation. The live results above precede this metadata-only version bump; integration was not rerun for the bump.

### Commands

Select the intended Ruby, then run from the repository root:

```sh
gem install bundler -v 2.5.23
bundle _2.5.23_ install
bundle _2.5.23_ exec rake test
```

Newer dependencies on a compatible Ruby:

```sh
BUNDLE_GEMFILE=gemfiles/latest.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/latest.gemfile bundle exec rake test
```

Live tests with Node 24.11.0 selected:

```sh
npm ci --prefix test/integration --no-audit --no-fund
bundle _2.5.23_ exec rake integration
```

The first run downloads MongoDB 8.0.17 into the OS temporary cache and needs network access. `NODE=/absolute/path/to/node` selects an executable. Node/MongoDB are test dependencies, not SDK runtime dependencies. Rake passes the selected Ruby to the runner. See the [workflow](.github/workflows/ruby.yml).

## Limits and observations

- Existing Ruby 3.1.6 cannot load `socket`; its SDK suite was not run.
- Other server versions/adapters, replica routing, production storage, TLS/proxies, mail/push/hooks, and exhaustive permissions/operators/dependency combinations are not certified.
- ActiveModel 7.2/8.0 were not separately tested; branches 7.1 and 8.1 were tested.
- Bundler 2.5.23 emits non-fatal Ruby 4 constant warnings. Newer-dependency runs use Bundler 4.0.8.
- Gem building warns about open-ended standard-library requirements; builds succeed.
- Temporary Ruby 3.0 needed compiler adjustments and a rebuilt socket extension. User-installed interpreters were not repaired/replaced.
- Parse Server logs include future-default warnings; these are not SDK failures.
- Remote CI, push, and publication were not performed. Version is now 2.0.0 on branch `ruby-3-rest-compatibility`.
