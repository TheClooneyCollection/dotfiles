# Swift specifics

How the rules in [SKILL.md](SKILL.md) look in Swift with Swift Testing. The examples use a small weather app.

## Dependencies

```swift
nonisolated struct Dependencies: Sendable {
    typealias FetchCities = @Sendable () async throws -> [City]
    typealias FetchForecast = @Sendable (City) async throws -> Forecast
    typealias Now = @Sendable () -> Date

    let fetchCities: FetchCities
    let fetchForecast: FetchForecast
    let now: Now
}

nonisolated extension Dependencies {
    static func live(configuration: APIConfiguration) -> Dependencies {
        let client = APIClient(fetch: URLSession.shared.data(from:), ...)
        let repo = ForecastRepository(apiClient: client)
        return Dependencies(
            fetchCities: repo.fetchCities,
            fetchForecast: repo.fetchForecast(city:),
            now: { Date() },
        )
    }
}
```

- Closures are `@Sendable` typealiases; structs that hold them are `nonisolated` and `: Sendable` explicitly, so a non-`Sendable` field fails at the definition.
- Pass methods as closures (`repo.fetchForecast(city:)`); the receiver needs no protocol.
- Repositories and clients are `nonisolated struct`s holding closures. View models are `@Observable` classes taking the closures they use in `init`.
- `Dependencies+Live.swift` is the one composition root; `Dependencies+Preview.swift` wires previews the same way.

## Test factories and fixtures

All in `<App>Tests/Fixtures/`: test-only extensions on app types in `Extensions.swift`, fakes in their own file (`FakeNetworking.swift`).

```swift
extension ForecastViewModel {
    /// A view model for tests. Pass what the test uses; anything left out crashes if called.
    static func test(
        fetchCities: @escaping Dependencies.FetchCities = { fatalError("not implemented") },
        fetchForecast: @escaping Dependencies.FetchForecast = { _ in fatalError("not implemented") },
    ) -> ForecastViewModel {
        ForecastViewModel(fetchCities: fetchCities, fetchForecast: fetchForecast)
    }
}

nonisolated extension Forecast {
    /// A valid London forecast. Override one field to test it on its own.
    static func test(city: City = .london, highCelsius: Decimal = Decimal(string: "14.5")!) -> Forecast { ... }
}
```

- Named constants for common values (`City.london`, `APIConfiguration.test`).
- A fixture that cannot fail uses `try!` inside `// swiftlint:disable force_try` with a one-line reason: a throw there is a broken fixture.
- Fakes return closures matching the typealias: `FakeNetworking.fetch(using: [url: body])`, `FakeNetworking.fetch(statusCode: 403)`.

## Tests

```swift
@MainActor
struct ForecastViewModelTests {
    // The user picks Paris, so the summary row shows its high of 21°.
    @Test func summaryRowShowsHighAfterPickingCity() async {
        let vm = ForecastViewModel.test(
            fetchCities: { [.paris] },
            fetchForecast: { _ in Forecast.test(city: .paris, highCelsius: 21) },
        )
        await vm.load()

        vm.select(city: .paris)

        #expect(vm.summaryRow == ForecastRowState(city: .paris, highCelsius: 21, trend: .rising))
    }
}
```

- Swift Testing: `@Test`, `#expect`, `#require`. View model suites are `@MainActor`.
- The comment above each test is the scenario; the function name says the outcome.
- Assert on view state values (`ForecastRowState`) with `==`, not on individual private fields.
- To check what reached a boundary, the fake closure records into a local actor or `Mutex`-guarded array and the test asserts on its contents after the flow.
- Tests mirror app folders with a `Tests` suffix (`Networking/` → `NetworkingTests/`).
- Coverage: the project's `scripts/coverage.sh`, overall and without the UI.
