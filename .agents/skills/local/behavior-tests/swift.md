# Swift specifics

How the rules in [SKILL.md](SKILL.md) look in Swift with Swift Testing. Reference project: `~/Source/Projects/PrivateWorkspace/2026-10-arq-home-task/ExchangeCalculator` (`Dependencies/`, `ExchangeCalculatorTests/Fixtures/`, `ExchangeCalculatorTests/ViewModelsTests/`).

## Dependencies

```swift
nonisolated struct Dependencies: Sendable {
    typealias FetchTickers = @Sendable ([Currency.Code]) async throws -> [Ticker]
    typealias Now = @Sendable () -> Date

    let fetchTickers: FetchTickers
    let now: Now
}

nonisolated extension Dependencies {
    static func live(configuration: APIConfiguration) -> Dependencies {
        let client = APIClient(fetch: URLSession.shared.data(from:), ...)
        let repo = TickerRepository(apiClient: client)
        return Dependencies(fetchTickers: repo.fetchTickers(codes:), now: { Date() })
    }
}
```

- Closures are `@Sendable` typealiases; structs that hold them are `nonisolated` and `: Sendable` explicitly, so a non-`Sendable` field fails at the definition.
- Pass methods as closures (`repo.fetchTickers(codes:)`); the receiver needs no protocol.
- Repositories and clients are `nonisolated struct`s holding closures. View models are `@Observable` classes taking the closures they use in `init`.
- `Dependencies+Live.swift` is the one composition root; `Dependencies+Preview.swift` wires previews the same way.

## Test factories and fixtures

All in `<App>Tests/Fixtures/`: test-only extensions on app types in `Extensions.swift`, fakes in their own file (`FakeNetworking.swift`).

```swift
extension ExchangeViewModel {
    /// A view model for tests. Pass what the test uses; anything left out crashes if called.
    static func test(
        fetchCatalog: @escaping Dependencies.FetchCatalog = { fatalError("not implemented") },
        fetchTickers: @escaping Dependencies.FetchTickers = { _ in fatalError("not implemented") },
    ) -> ExchangeViewModel {
        ExchangeViewModel(fetchCatalog: fetchCatalog, fetchTickers: fetchTickers)
    }
}

nonisolated extension Ticker {
    /// A valid MXN ticker. Override one field to test it on its own.
    static func test(code: Currency.Code = .mxn, bid: Decimal = Decimal(string: "18.78068")!) -> Ticker { ... }
}
```

- Named constants for common values (`Currency.Code.mxn`, `APIConfiguration.test`).
- A fixture that cannot fail uses `try!` inside `// swiftlint:disable force_try` with a one-line reason: a throw there is a broken fixture.
- Fakes return closures matching the typealias: `FakeNetworking.fetch(using: [url: body])`, `FakeNetworking.fetch(statusCode: 403)`.

## Tests

```swift
@MainActor
struct ExchangeViewModelTests {
    // The user types 100 with COP selected, so the get row shows 338,724.
    @Test func getRowShowsConvertedAmountAfterTyping() async {
        let vm = ExchangeViewModel.test(
            fetchCatalog: { .test([.cop]) },
            fetchTickers: { _ in [Ticker.test(code: .cop, bid: Decimal(string: "3387.24")!)] },
        )
        await vm.load()

        vm.edit("100", in: .usdc)

        #expect(vm.getRow == CurrencyRowState(currency: .cop, amount: 338_724, sign: .plus))
    }
}
```

- Swift Testing: `@Test`, `#expect`, `#require`. View model suites are `@MainActor`.
- The comment above each test is the scenario; the function name says the outcome.
- Assert on view state values (`CurrencyRowState`) with `==`, not on individual private fields.
- To check what reached a boundary, the fake closure records into a local actor or `Mutex`-guarded array and the test asserts on its contents after the flow.
- Tests mirror app folders with a `Tests` suffix (`Networking/` → `NetworkingTests/`).
- Coverage: the project's `scripts/coverage.sh`, overall and without the UI.
