---
name: behavior-tests
description: Write tests as the user's flow and inject dependencies as plain functions, so coverage is near total and cheap. Use when writing or reviewing tests, adding test doubles or fakes, wiring dependency injection, or raising coverage, in any language.
---

Tests describe **behaviour**: what a user (or a calling system) does and what they then observe. The code under test is a black box behind its public surface. A test that still passes after any refactor that keeps behaviour, and fails on any change that breaks it, is the target.

Language specifics: Swift in [swift.md](swift.md). For other languages, map each rule below onto its plainest idiom (function parameters, a record of functions, a small interface with one method per capability).

## Dependencies are functions

- **Inject capabilities, not objects.** Each dependency is one function for one capability: `listFiles`, `download`, `upload`, `readToken`, `now`. Group them in a plain record (`Dependencies`) when several travel together. Reach for an interface only when the language makes functions awkward, and then keep it to the capabilities used.
- **Each unit takes only what it uses.** A repository takes the client functions it calls; a view model takes the repository methods it calls, passed as functions. Narrow parameters keep test setup to the lines that matter.
- **One composition root.** Real implementations are wired in exactly one place (`Dependencies.live(...)`, `main`, the app entry point). Everything below it is pure wiring-free code.
- **Inject the world.** Time, randomness, IDs, file system, network, environment and threads/schedulers all come in as dependencies. Tests advance an injected clock and never sleep.

## Test doubles

- **Test factories crash by default.** Every type with dependencies gets a test-only factory (`.test(...)`) whose every dependency defaults to "crash: not implemented". A test passes only the functions its flow uses, so an unexpected call fails loudly and names itself. Give a dependency a harmless default only when nearly every test needs that exact value, and say why in a comment.
- **Value fixtures override one field.** `Thing.test(field: default, ...)` builds a valid value; a test changes the one field it is about, so the input that matters is the only one written.
- **Fakes are data.** A fake is a dictionary of routes, an in-memory store with a counter, a list that records what arrived. No mocking framework, no call-count or argument-order assertions.
- **Shared helpers live in the test target's fixtures folder**, never in production code.

## Writing a test

1. Name and open the test with the scenario as the user lives it, in one line: "plays, the PC changed the Cloud meanwhile, upload stops and asks".
2. Arrange with the factory and fixtures, passing only the dependencies the flow touches.
3. Act as the user's actions, in order (`load()`, `edit("100")`, `swap()`), through the public surface.
4. Assert on what is observable: the state the user sees, the value returned, and what reached a fake boundary (the files in the fake store, the request the fake server received). Leave internal calls, private state and the order of internal steps unasserted.

## Shape the code for it

- **Split pure derivation from behaviour.** Code where the same input always gives the same output (formatting, mapping, view state) is a pure function tested as input → output tables. Code that changes state, awaits or holds a dependency is tested as a flow.
- **Keep logic out of the composition root and the thin adapters** around real systems (a C# bridge, a Keychain call, an HTTP client). Adapters stay a few lines each, so the untested surface is tiny and everything with a decision in it sits behind injected functions.

## Done

A change is done when every behaviour it adds or alters has a flow test or an input → output case, each failure path the user can hit (offline, conflict, partial failure, retry, empty) has its own test, and the coverage report shows the logic layers near full with the remaining gaps confined to the composition root and adapters.
