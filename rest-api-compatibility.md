# Parse REST API compatibility review

Checked: 2026-11-07. Scope: the working tree, the [REST guide](https://docs.parseplatform.org/rest/guide/), request contracts, and a pinned live server.

Related: [findings](compatibility-findings.md), [Ruby changes](ruby-compatibility.md), [validation](compatibility-validation.md), [support plan](rest-api-support.md).

## Verdict

All three confirmed REST defects are fixed. Ten live tests pass on **Parse Server 9.10.7 / MongoDB 8.0.17**, using Ruby 3.0.7 and 4.0.2. The tested behavior is compatible with this baseline. Full endpoint conformance and the deployed environment remain unverified.

## Original defects and repairs

| Defect | Before | Current behavior | Sources |
| --- | --- | --- | --- |
| Advanced options | `readPreference` and `excludeKeys` entered `where`, changing query meaning. | Known options compile at the top level; `server_options` explicitly forwards newer options. | [query](lib/parse/query.rb), [contracts](test/lib/parse/rest_api_test.rb) |
| Installation header | Constant was `Parse-Installation-Id`; signup/login did not forward installation options. | Uses `X-Parse-Installation-Id`; `installation_id:` reaches the resulting session. | [protocol](lib/parse/client/protocol.rb), [client](lib/parse/client.rb), [users](lib/parse/api/users.rb), [user model](lib/parse/model/classes/user.rb) |
| Job tracking | HTTP 200 with `{}` lost the job-status header; helper returned nil. | Headers are retained. `header` is case-insensitive. `job_status_id` exposes the ID; `Parse.trigger_job` returns it with a legacy body fallback. | [response](lib/parse/client/response.rb), [middleware](lib/parse/client/body_builder.rb), [helper](lib/parse/client.rb) |
| Distinct Ruby keywords | Positional options raised before HTTP. | Forwards keywords; contract and live distinct checks pass. | [query](lib/parse/query.rb), [tests](test/lib/parse/client_test.rb) |

The job response matches the pinned server and its [FunctionsRouter](https://github.com/parse-community/parse-server/blob/9.10.7/src/Routers/FunctionsRouter.js). Guide contracts: [read preference](https://docs.parseplatform.org/rest/guide/#read-preference), [installation pairing](https://docs.parseplatform.org/rest/guide/#pairing-session-with-installation), [jobs](https://docs.parseplatform.org/rest/guide/#triggering-background-jobs).

## Additional support

| Area | Change and evidence |
| --- | --- |
| Batch | Default 20; configurable per client/submission. Contracts capture 20 + 1 chunks. Live creation of 21 objects passes under `/sdk/parse`. Manual batch paths must include the mount prefix. |
| Projection | Existing comma format retained; comma and JSON-array key selection both pass on 9.10.7. |
| Files | Added `delete_file(name_or_file, **opts)`; binary upload/deletion passes with the in-memory fixture adapter. |
| Schema | Added `delete_schema(class_name, **opts)`; create/update/fetch/delete-empty-class passes. |
| Impersonation | Added client/model `login_as`; POST query/master headers are contract-tested and session creation passes live. |
| Pipeline | Added `aggregate_pipeline(class_name, stages, **opts)`; operators/field paths pass unchanged; live group/sum passes. |
| Functions | Helpers forward headers/options. Contracts verify session forwarding without a master header. |
| Requests | Non-GET query parameters retained; empty successful bodies become `{}`; caller headers copied. Live POST and frozen-header/HTTP-204 contracts pass. |

Batch limits are configurable and master/maintenance requests have exemptions in the [server implementation](https://github.com/parse-community/parse-server/blob/9.10.7/src/batch.js). The old default of 50 was a mismatch, not proof that every larger batch failed.

## Boundaries

Live coverage includes CRUD/errors, typed values, selected atomic updates, filtering/order/count/distinct/projection, aggregation, batches, signup/login/current user/current session/logout, installation pairing, impersonation, one private-object ACL case, files, schemas, functions, and successful job completion.

Roles/installations beyond pairing, config, hooks, restricted-session workflows, schema indexes/CLPs, advanced operators, provider authentication, mail, and push lack complete live coverage. Existing routes or generic requests may support them; a missing convenience helper does not mean REST access is unavailable.

No production credentials/data were used. File tests use a fixture adapter. Read preference `PRIMARY` was tested on standalone MongoDB; replica-set routing was not. See the [support plan](rest-api-support.md) for priorities and extension requirements.
