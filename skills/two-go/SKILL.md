---
name: two-go
description: Use when writing, editing, or debugging API/HTTP tests with the two-go library for Node. Covers the fluent go() request builder, inline expectations, the expect value-assertion API, soft assertions, schema validation, sessions and auth chaining, polling for eventual results, snapshots, fake data, and importing OpenAPI or Postman collections.
---

# Writing tests with two-go

two-go is a zero-dependency library for testing HTTP APIs from Node. You build a
request with a chainable API, attach the checks you care about, and `await` it.
If a check fails it throws, so no special test runner is required. It works
standalone and inside node:test, Jest, Vitest, or Mocha.

Install it with `npm install two-go`. It needs Node 18 or newer and is ESM, so
import it with `import { go } from "two-go"`.

## The core request chain

```js
import { go } from "two-go";

await go("https://api.example.com")
  .get("/users")
  .bearer(token)
  .expectStatus(200)
  .expectHeader("content-type", /json/)
  .expectJson("data[0].id", 1);
```

`go(baseUrl)` returns a client. Call `.get`, `.post`, `.put`, `.patch`, or
`.delete` with a path. Attach a body with `.json(obj)`, headers with
`.header(name, value)`, and auth with `.bearer(token)`. Add expectations, then
`await` the chain. Reuse one client across requests, with shared headers set on
the client:

```js
const api = go({
  baseURL: "https://api.example.com",
  headers: { authorization: `Bearer ${token}` },
});
await api.get("/health").expectOk();
```

## Status expectations

| Method | Checks |
| --- | --- |
| `expectStatus(code)` | status equals `code` |
| `expectStatusIn(...codes)` | status is one of `codes` |
| `expectOk()` | status is 2xx |
| `expectCreated()` / `expectAccepted()` / `expectNoContent()` | 201 / 202 / 204 |
| `expectBadRequest()` / `expectUnauthorized()` / `expectForbidden()` / `expectNotFound()` | 400 / 401 / 403 / 404 |
| `expectClientError()` / `expectServerError()` / `expectRedirect()` | 4xx / 5xx / 3xx |

## Header and body expectations

| Method | Checks |
| --- | --- |
| `expectHeader(name, matcher?)` | header is present, and matches if you pass a matcher |
| `expectHeaderContains(name, substr)` | header value contains the substring |
| `expectContentType(type)` | content type contains `type` |
| `expectCookie(name, matcher?)` | a set-cookie is present, and matches if given |
| `expectJson(path, expected?)` | value at `path` exists, and matches if you pass `expected` |
| `expectJsonLength(path, n)` | array or string at `path` has length `n` |
| `expectJsonContains(path, value)` | array contains a matching item (objects match by subset) |
| `expectJsonSchema(schema)` | the body validates against a JSON schema |
| `expectSorted(path, options?)` | the array at `path` is sorted, options `{ key?, order? }` |
| `expectBody(matcher)` | the whole body matches, deep compare for objects |
| `expectBodyContains(substr)` | the raw text body contains `substr` |
| `expectTimeBelow(ms)` | the round trip was under `ms` |

The `path` is a dotted or bracketed JSON path like `data[0].id`. The matcher you
pass to `expectJson` can be a literal, a regular expression, a predicate
function, or an object or array compared by deep equality. For a subset match
on an object, use `expectJsonContains`:

```js
await api.get("/users")
  .expectJson("data[0].role", (role) => role === "admin")
  .expectJsonContains("meta", { page: 1 })
  .expectHeader("x-trace-id", /^[0-9a-f-]+$/);
```

## Asserting on the returned response

Every awaited chain resolves to a response you can keep asserting on with the
value `expect` API, which mirrors Jest matchers:

```js
const res = await api.get("/users").expectOk();
res.expectValue("data[0].id").toBeGreaterThan(0);
res.expectValue("data").toHaveLength(2);
res.expectJsonContains("users", { id: 2 });
```

## Soft assertions

Collect several failures and report them together instead of stopping at the
first one:

```js
import { softly } from "two-go";

softly((expect) => {
  expect(res.status).toBe(200);
  expect(res.body.data).toHaveLength(2);
});
```

## Sessions and auth chaining

A session shares named variables across requests. Use `extract` to capture a
value from one response and fill `{{name}}` placeholders in the path, headers,
and body of later requests. Pass `session({ baseURL, cookies: true })` to also
carry cookies:

```js
import { session } from "two-go";

const s = session("https://api.example.com");

await s.post("/login")
  .json({ user: "ada", pass: "secret" })
  .extract("token", "data.token");

await s.get("/me")
  .header("authorization", "Bearer {{token}}")
  .expectOk()
  .expectJson("user", "ada");
```

## Polling for eventual results

When a value shows up later, for example after a job finishes or a record gets
indexed, retry until it appears:

```js
import { eventually } from "two-go";

await eventually(
  () => api.get("/report/42").expectJson("ready", true),
  { timeout: 5000, interval: 250 }
);
```

`pollUntil(fn, predicate, options)` is the value-based variant: it calls `fn`
until `predicate(result)` is truthy and resolves with that result:

```js
import { pollUntil } from "two-go";

const job = await pollUntil(
  () => api.get("/jobs/7").then((r) => r.body),
  (body) => body.status === "done",
  { timeout: 10000, interval: 500 }
);
```

## Snapshots

```js
import { toMatchSnapshot } from "two-go";

toMatchSnapshot(res.body, "users-list");
```

`matchSnapshot` is another name for `toMatchSnapshot`.

## Schema validation

Validate a body against a JSON schema, or infer one from a real response and
reuse it as a contract test:

```js
import { inferSchema } from "two-go";

const res = await api.get("/users").expectOk();
const schema = inferSchema(res.body); // same as res.toSchema()
await api.get("/users").expectJsonSchema(schema);
```

## Fake data

Build payloads without a faker dependency:

```js
import { faker } from "two-go";

const payload = {
  id: faker.uuid(),
  email: faker.email(),
  name: faker.fullName(),
  age: faker.int(18, 80),
};
```

## Importing OpenAPI and Postman

```js
import { fromOpenapi, fromPostman } from "two-go/importers";
```

These turn a spec or a collection into ready requests so you do not have to type
every path by hand.

## BDD style

`two-go/bdd` gives runner-agnostic Gherkin-style steps. Step helpers are
capitalized: `Given`, `When`, `Then`, `And`.

```js
import { test } from "node:test";
import { scenario, Given, When, Then } from "two-go/bdd";

test("creating a user", scenario([
  Given("a payload", (w) => { w.payload = { name: "Ada" }; }),
  When("it is posted", async (w) => { w.res = await api.post("/users").json(w.payload); }),
  Then("it is created", (w) => w.res.expectStatus(201)),
]));
```

## How to write a test file

Prefer node:test, since it needs no extra dependency:

```js
import { test } from "node:test";
import { go } from "two-go";

test("GET /users returns the first user", async () => {
  await go("https://api.example.com")
    .get("/users")
    .expectStatus(200)
    .expectJson("data[0].id", 1);
});
```

## Guidance when authoring tests

- Start from the base URL and a single shared client, then branch per request.
- Assert status first, then headers, then body. Keep one behavior per test.
- For fields whose exact value is not stable, use a predicate, a regular
  expression, or a subset match (`expectJsonContains(path, partial)` or `expectValue(path).toMatchObject(partial)`).
- For flows that depend on prior state, such as login then fetch, use a session
  and `extract` rather than copying tokens by hand.
- For values that appear after a delay, use `eventually` instead of a fixed sleep.
- Prefer `expectJsonSchema` for contract style checks over asserting every field.
