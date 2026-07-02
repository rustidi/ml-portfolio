---
name: swiftui-patterns
description: SwiftUI architecture patterns — @Observable state management, view composition, NavigationStack, performance optimization, modern iOS/macOS UI.
triggers:
  - "SwiftUI"
  - "@Observable"
  - "NavigationStack"
  - "iOS view"
  - "@Bindable"
  - "view performance"
applies_to:
  - "the iOS/macOS app"
---

# SwiftUI Patterns

Modern SwiftUI patterns for building declarative, performant user interfaces on Apple platforms. Covers the Observation framework, view composition, type-safe navigation, and performance optimization.

## When to Activate

- Building SwiftUI views and managing state (`@State`, `@Observable`, `@Binding`)
- Designing navigation flows with `NavigationStack`
- Structuring view models and data flow
- Optimizing rendering performance for lists and complex layouts
- Working with environment values and dependency injection in SwiftUI

## State Management

### Property Wrapper Selection

Choose the simplest wrapper that fits:

| Wrapper | Use Case |
|---------|----------|
| `@State` | View-local value types (toggles, form fields, sheet presentation) |
| `@Binding` | Two-way reference to parent's `@State` |
| `@Observable` class + `@State` | Owned model with multiple properties |
| `@Observable` class (no wrapper) | Read-only reference passed from parent |
| `@Bindable` | Two-way binding to an `@Observable` property |
| `@Environment` | Shared dependencies injected via `.environment()` |

### @Observable ViewModel

Use `@Observable` (not `ObservableObject`) — it tracks property-level changes so SwiftUI only re-renders views that read the changed property:

```swift
@Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    var searchText = ""

    private let repository: any ItemRepository

    init(repository: any ItemRepository = DefaultItemRepository()) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await repository.fetchAll()) ?? []
    }
}
```

### View Consuming the ViewModel

```swift
struct ItemListView: View {
    @State private var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel = ItemListViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .searchable(text: $viewModel.searchText)
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.load() }
    }
}
```

### Environment Injection

Replace `@EnvironmentObject` with `@Environment`:

```swift
// Inject
ContentView()
    .environment(authManager)

// Consume
struct ProfileView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Text(auth.currentUser?.name ?? "Guest")
    }
}
```

## View Composition

### Extract Subviews to Limit Invalidation

Break views into small, focused structs. When state changes, only the subview reading that state re-renders:

```swift
struct OrderView: View {
    @State private var viewModel = OrderViewModel()

    var body: some View {
        VStack {
            OrderHeader(title: viewModel.title)
            OrderItemList(items: viewModel.items)
            OrderTotal(total: viewModel.total)
        }
    }
}
```

### ViewModifier for Reusable Styling

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

## Navigation

### Type-Safe NavigationStack

Use `NavigationStack` with `NavigationPath` for programmatic, type-safe routing:

```swift
@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

enum Destination: Hashable {
    case detail(Item.ID)
    case settings
    case profile(User.ID)
}

struct RootView: View {
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { dest in
                    switch dest {
                    case .detail(let id): ItemDetailView(itemID: id)
                    case .settings: SettingsView()
                    case .profile(let id): ProfileView(userID: id)
                    }
                }
        }
        .environment(router)
    }
}
```

## Performance

### Use Lazy Containers for Large Collections

`LazyVStack` and `LazyHStack` create views only when visible:

```swift
ScrollView {
    LazyVStack(spacing: 8) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Stable Identifiers

Always use stable, unique IDs in `ForEach` — avoid using array indices:

```swift
// Use Identifiable conformance or explicit id
ForEach(items, id: \.stableID) { item in
    ItemRow(item: item)
}
```

### Avoid Expensive Work in body

- Never perform I/O, network calls, or heavy computation inside `body`
- Use `.task {}` for async work — it cancels automatically when the view disappears
- Use `.sensoryFeedback()` and `.geometryGroup()` sparingly in scroll views
- Minimize `.shadow()`, `.blur()`, and `.mask()` in lists — they trigger offscreen rendering

### Equatable Conformance

For views with expensive bodies, conform to `Equatable` to skip unnecessary re-renders:

```swift
struct ExpensiveChartView: View, Equatable {
    let dataPoints: [DataPoint] // DataPoint must conform to Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dataPoints == rhs.dataPoints
    }

    var body: some View {
        // Complex chart rendering
    }
}
```

## Previews

Use `#Preview` macro with inline mock data for fast iteration:

```swift
#Preview("Empty state") {
    ItemListView(viewModel: ItemListViewModel(repository: EmptyMockRepository()))
}

#Preview("Loaded") {
    ItemListView(viewModel: ItemListViewModel(repository: PopulatedMockRepository()))
}
```

## Anti-Patterns to Avoid

- Using `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` in new code — migrate to `@Observable`
- Putting async work directly in `body` or `init` — use `.task {}` or explicit load methods
- Creating view models as `@State` inside child views that don't own the data — pass from parent instead
- Using `AnyView` type erasure — prefer `@ViewBuilder` or `Group` for conditional views
- Ignoring `Sendable` requirements when passing data to/from actors

## Custom Tab Bar / Bottom Overlay — the `.safeAreaInset` Trap

**A recurrent class of bug (cost four iterations to get right):** building a custom bottom tab bar via `.safeAreaInset(edge: .bottom)` is the wrong tool. `safeAreaInset` reserves space for content **above** the system safe-area inset (~34pt home-indicator zone on Face ID iPhones). Items sit at the **top** of that slot. Even if you paint the background with `.background(_:ignoresSafeAreaEdges: .bottom)`, the fill covers the home-indicator zone but the items stay high → a visible 40–50pt gap between labels and the screen edge.

**Correct pattern (production iOS-style tab bar):**

```swift
var body: some View {
    GeometryReader { proxy in
        let bottomSafe = proxy.safeAreaInsets.bottom        // ≈34pt on Face ID phones
        let tabbarVisibleHeight: CGFloat = 64               // icons + labels + top/bottom padding
        let totalReserveHeight = tabbarVisibleHeight + max(bottomSafe - 8, 0)

        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, totalReserveHeight)        // content does not slide under the tab bar
            tabbar(bottomSafe: bottomSafe)                   // tab bar in bottom alignment ZStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .bottom)         // ZStack bottom = real screen edge
        .ignoresSafeArea(.keyboard)
    }
}

private func tabbar(bottomSafe: CGFloat) -> some View {
    // Adaptive formula: labels sit exactly in the safe-area zone, snug above the home indicator (~8pt gap).
    let breathing: CGFloat = bottomSafe > 0 ? max(bottomSafe - 22, 6) : 10
    return HStack(spacing: 0) { items }
        .padding(.top, 12)
        .padding(.bottom, breathing)                         // drops labels into the safe-area zone
        .background(.ultraThinMaterial)
        .background(Color.appBackground)
}
```

**Device coverage (Face ID iPhones safe=34 / Touch ID SE safe=0):**
- Face ID (safe=34): breathing = 12pt → labels ~12pt from the edge, right above the home indicator
- Touch ID SE (safe=0): breathing = 10pt → snug bottom, no home indicator
- Taller devices (safe=39): breathing = 17pt → proportionally larger

**When `.safeAreaInset` IS appropriate:** a floating action button over scroll content, or a sticky bottom toolbar that should sit **above** the safe area (the typical case — not a tab bar).

## Platform-Conditional System APIs (iOS Simulator vs Real Device)

Apple system frameworks may not work, or may return `nil`/`denied`, in the iOS Simulator. **Always verify simulator support before implementation** and add a `#if targetEnvironment(simulator)` fallback for dev/testing.

**Confirmed gaps:**

| Framework / API | Simulator behavior | Workaround |
|----------|--------------------|------------|
| `INFocusStatusCenter` (Intents) | `authorizationStatus` always `.denied`, `focusStatus.isFocused` always `nil` | `#if targetEnvironment(simulator)` → assume `.authorizedOn` for dev |
| HealthKit | Most read/write fails — no real HealthKit data | Mock HealthKit data layer |
| CallKit | Incoming-call simulation is limited | Manual trigger via test app |
| Push notifications (APNs) | Only `simctl push` with a payload file | Don't rely on real APNs flow |
| Camera (real video stream) | Simulates a static image | Mock camera frames |
| Background modes (audio recording in background) | May work but without real OS suspension | Test on a real device |

**Pattern for a system API with graceful simulator fallback:**

```swift
@State private var dndState: DNDState = .checking

private func refreshDNDState() {
    #if targetEnvironment(simulator)
    dndState = .authorizedOn          // dev unblock: simulator doesn't support Focus
    #else
    let auth = INFocusStatusCenter.default.authorizationStatus
    guard auth == .authorized else {
        dndState = .notAuthorized
        return
    }
    let isFocused = INFocusStatusCenter.default.focusStatus.isFocused
    dndState = (isFocused == true) ? .authorizedOn : .authorizedOff
    #endif
}
```

**Rule:** for critical features (auth, payments, anything safety-sensitive), the real API check **must** run on a physical device during final verification. A simulator bypass is dev convenience only.

## References

See skill: `swift-actor-persistence` for actor-based persistence patterns.
See skill: `swift-protocol-di-testing` for protocol-based DI and testing with Swift Testing.
