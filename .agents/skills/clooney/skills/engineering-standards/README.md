# engineering-standards

Build and review app code with standards for simple objects, single responsibility, strong boundaries, dependency injection and testable state. Each rule starts with a principle and keeps Swift as one example.

**Why:** I want every app I build to start from the same foundation: simple objects, strong single responsibility, strong boundaries, full dependency injection, and state and logic you can test. Writing it down once means agents build to that standard by default, instead of me re-explaining it on every project.

**Use it:** when designing app architecture, wiring dependencies, writing view models or view states, mapping network data and errors, applying code layout conventions, or reviewing code against these standards.

**Needs:** Nothing to install. Test shape, doubles, factories and fixtures follow the `behavior-tests` skill.

## Files

- [SKILL.md](SKILL.md): five core rules, reference pointers and the completion check.
- [references/structure.md](references/structure.md): rules 6–16 for structure, dependencies, serialization, semantic payloads, explicit argument labels, grouping and enum projections.
- [references/layout.md](references/layout.md): rule 17 for multiline conditions, arguments, parameters and nested calls.
- [references/screen-state.md](references/screen-state.md): rules 18–23 for screen state and presentation.
- [references/tests.md](references/tests.md): rules 24–28 for test boundaries, fixtures, offline coverage and wire output.
