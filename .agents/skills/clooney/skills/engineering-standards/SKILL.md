---
name: engineering-standards
description: Build and review app code to a fixed set of engineering standards (simple objects, single responsibility, strong boundaries, full dependency injection, testable state and logic), each stated as a principle with its Swift or SwiftUI form. Use when designing or reviewing app architecture, wiring dependency injection, writing view models or view states, mapping network responses and errors into domain types, or when the user says "our standards" or "to our engineering standards".
---

# Engineering standards

Principle first, then the Swift form as one example; in another language, use its plainest idiom for the same rule. Test shape, doubles, factories and fixtures are in the `behavior-tests` skill; the rules in the tests reference add only what that skill leaves open.

## Core

1. **Simple objects.** Values and functions before classes and interfaces. Domain and view-state types are immutable values; computation is pure functions grouped by topic. A class only where mutable, observed state lives (the view model); an interface only for a real boundary, never one interface and one mock per dependency. Swift: `let`-only structs and enums, `static func`s on a `nonisolated enum`, one `@Observable` class per screen.
2. **Strong single responsibility.** One type, one job, named after the job. Networking alone is four types: configuration (base URL, version), endpoints (paths), client (fetch and decode), mapper (wire type to domain). The reverse holds too: actions that share one piece of state stay in one type instead of being split to shorten it.
3. **Strong boundaries.** Each layer speaks only its own types, and raw data stops at the edge. A weather DTO holds the server's strings; the repository maps it to a `Forecast` with typed temperatures; every failure becomes the layer's own error before it crosses. Callers consume capabilities (`fetchForecast`), never construct lower layers. A view sees view states, never a DTO or the client.
4. **Full dependency injection.** Every side effect (network, stored data, a delay's length) is passed in at construction with no default, so a caller can't forget it and a test can't be fooled by a built-in. One composition root: the entry point reads the configuration switches and builds the live wiring as locals in one function; preview or demo wiring is a second set that doesn't ship. Nothing below the root reads a global. Time and delays are injected only when a test needs to control them; a presentation delay doesn't earn a clock. Swift: `@Sendable` closures in `init`; `Dependencies+Live.swift`, and `Dependencies+Preview.swift` behind `#if DEBUG`; no `URLSession.shared` outside the root.
5. **Testable state and logic.** State is a value you can assert on: one state enum with payloads, readable by all and written only by its owner's actions. Logic is a pure function whose inputs (locale, units, the loaded data) are parameters, so a test needs no environment. Tests drive the real types through the user's flow and fake only the outermost boundary. Swift: `enum State: Equatable`, `private(set) var state`, `#expect(viewModel.state == .loaded(expected))`.

## Reference

- Read [structure.md](references/structure.md) when separating view models from view states, wiring dependencies, defining configuration, concurrency, validation and error boundaries, choosing request serialization or boundary payloads, or grouping members and function stages.
- Read [screen-state.md](references/screen-state.md) when deriving screen state, formatting values, guarding async actions, extracting components or documenting escape hatches.
- Read [tests.md](references/tests.md) when choosing test boundaries, recording fixture provenance, covering screen states offline or verifying request wire output.

## Done

Each changed type has one job and a name that says it, every side effect enters through its initialiser, every new boundary has its own types and error, and each behaviour has a test that reads as the user's flow with only the world faked.
