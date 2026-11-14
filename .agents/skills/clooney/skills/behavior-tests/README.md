# behavior-tests

A way of writing tests that describe what the user does and sees, with dependencies injected as plain functions. Tests survive refactors, setup stays short, and coverage gets close to total cheaply.

**Why:** This is the way.™ My way. Tests written as the user's flow, dependencies injected as plain functions, test factories that crash on anything not provided, fakes as plain data, and an injected clock instead of sleeps. The result: tests that survive any refactor and near-total coverage, cheaply.

**Use it:** when writing or reviewing tests, adding fakes, wiring dependency injection, or raising coverage. Works in any language.

## The ideas

- **Dependencies are functions.** Inject one function per capability (`download`, `now`, `readToken`), not whole objects. Each unit takes only what it uses.
- **Inject the world.** Time, randomness, IDs, files, network and schedulers all come in from outside. Tests advance a fake clock and never sleep.
- **Test factories crash by default.** Any dependency a test did not provide fails loudly and names itself.
- **Fakes are data:** a dictionary of routes, an in-memory store. No mocking framework.
- **Tests read as user flows:** named after the scenario, acting through the public surface, asserting only on what is observable.
- **Pure logic is tested as input and output tables;** everything else as a flow.

## Files

- [SKILL.md](SKILL.md): the rules.
- [swift.md](swift.md): how they map onto Swift.
