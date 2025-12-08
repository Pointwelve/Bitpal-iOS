<!--
=============================================================================
SYNC IMPACT REPORT - Constitution v3.0.0
=============================================================================

VERSION CHANGE: 2.0.0 → 3.0.0 (Phase 2 → Phase 3 transition)

PHASE TRANSITION:
  - Phase 2 (Widgets): ✅ COMPLETE - All features shipped
  - Phase 3 (Visual Intelligence): 🔵 ACTIVE - Now in development

PHASE 2 DELIVERED:
  - Small, Medium, Large portfolio widgets
  - App Groups shared data layer
  - 30-minute timeline refresh
  - Offline support with cached data
  - Deep linking to Portfolio tab
  - Light/Dark mode support

PHASE 3 SCOPE (NOW ACTIVE):
  - Price charts per coin (1D, 1W, 1M, 1Y)
  - Portfolio value over time chart
  - Price alerts (push notifications)
  - Best/worst performers view
  - Portfolio allocation breakdown

TEMPLATES REQUIRING UPDATES:
  ✅ All templates remain valid for Phase 3

FOLLOW-UP TODOS: None

RATIONALE FOR v3.0.0:
  - Major version bump for phase transition (per governance)
  - Phase 2 Widgets feature complete and shipped
  - Phase 3 Visual Intelligence now active for implementation

=============================================================================
-->

# Bitpal iOS Constitution

## Core Principles

### I. Performance-First Architecture (NON-NEGOTIABLE)

**Performance is the core differentiator.** Every architectural decision, every line of code, every feature MUST prioritize smoothness and responsiveness. Laggy experiences are FORBIDDEN.

**Mandatory Performance Requirements:**

- **60fps UI smoothness**: All list scrolling, animations, and interactions MUST maintain 60fps minimum on iPhone 13 and newer devices.
- **Throttled updates**: Price updates occur at 30-second intervals (main app) or 30-minute intervals (widgets). Real-time updates are FORBIDDEN.
- **Two-tier caching**: Implement in-memory cache (fast reads) + Swift Data cache (persistent). Cache MUST be invalidated explicitly.
- **Batch API requests**: Multiple coin prices fetched in single requests. Individual requests per coin are FORBIDDEN.
- **LazyVStack for lists**: Lists with >10 items MUST use LazyVStack. Regular VStack is FORBIDDEN for long lists.
- **Non-blocking async operations**: UI updates MUST occur on MainActor. Blocking the main thread is FORBIDDEN.
- **Cached computed values**: Expensive calculations (P&L totals, portfolio values) MUST be cached with explicit invalidation.
- **Widget efficiency**: Widget timeline refreshes MUST be batched. Excessive background fetches are FORBIDDEN.

**Rationale**: The app's value proposition is performance. Compromising smoothness compromises the product's reason to exist. Users chose Bitpal specifically to escape laggy competitors.

**Validation**: Before shipping any feature, verify with Xcode Instruments that scrolling maintains 60fps and API calls are batched.

---

### II. Liquid Glass Design System

**Follow iOS 26 Liquid Glass design language.** Consistency with platform conventions ensures familiarity and reduces cognitive load.

**Design Requirements:**

- **Translucent materials**: Use `.ultraThinMaterial` for primary backgrounds, `.regularMaterial` for cards, `.thickMaterial` for emphasis.
- **Rounded corners**: 12-16pt corner radius for all cards and containers.
- **System colors**: Use semantic system colors (`.primary`, `.secondary`, `.green`, `.red`) for automatic Dark Mode support.
- **Dynamic Type**: Support `.medium` through `.accessibilityExtraLarge` dynamic type sizes.
- **Smooth animations**: Standard spring animation parameters: `response: 0.3, dampingFraction: 0.7`.
- **Minimum tap targets**: 44x44pt minimum (iOS Human Interface Guidelines compliance).
- **Consistent spacing**: Use defined spacing scale (xs: 4pt, sm: 8pt, md: 12pt, lg: 16pt, xl: 24pt, xxl: 32pt).
- **Widget design**: Widgets MUST match main app design language. Use system widget backgrounds.

**Rationale**: Platform consistency reduces development time, ensures accessibility, and provides users with familiar interaction patterns.

**Validation**: Visual review against iOS 26 HIG. All interactive elements MUST meet minimum tap target sizes.

---

### III. MVVM + Modern Swift Patterns

**Use lightweight MVVM architecture with modern Swift patterns.** Avoid over-engineering and heavy frameworks.

**Architectural Requirements:**

- **@Observable macro**: ViewModels MUST use `@Observable` (Swift 5.9+). ObservableObject is FORBIDDEN.
- **SwiftUI views are stateless**: Views are pure, declarative, and contain NO business logic.
- **ViewModels contain business logic**: Handle user actions, update state, coordinate with services.
- **Services are singletons**: API client, persistence manager, price update service use singleton pattern.
- **Swift Data for persistence**: Use Swift Data. Core Data is FORBIDDEN.
- **App Groups for sharing**: Widget extension MUST access data via App Groups shared container.
- **async/await for concurrency**: Use modern async/await. Combine publishers are FORBIDDEN.
- **Structs over classes**: Prefer structs unless reference semantics required.
- **Minimal external dependencies**: URLSession, Swift Data, SwiftUI, WidgetKit are sufficient. Third-party frameworks require explicit justification.

**Rationale**: Modern Swift patterns reduce boilerplate, improve compile times, and align with platform direction.

**Validation**: Code reviews MUST verify @Observable usage, stateless views, and minimal dependencies.

---

### IV. Data Integrity & Calculation Accuracy

**Financial calculations MUST be accurate and verifiable.** User trust depends on correct P&L calculations.

**Data Integrity Requirements:**

- **Decimal type for money**: Use `Decimal` type for all prices, quantities, and calculations. Double and Float are FORBIDDEN for financial values.
- **P&L calculations tested**: Transaction calculations MUST have unit tests before implementation.
- **Widget calculations consistent**: Widget P&L MUST match main app exactly. No approximations.
- **Cached computed values**: Portfolio totals cached with explicit invalidation.
- **API response parsing validated**: CoinGecko API responses MUST be parsed defensively.
- **Proper transaction accounting**: Standard accounting principles for average cost calculation.

**Rationale**: Financial apps live or die by accuracy. A single incorrect P&L calculation destroys user trust permanently.

**Validation**: Unit tests for all calculation logic. Widget values MUST match main app values exactly.

---

### V. Phase Discipline (Scope Management)

**Current phase scope is FROZEN.** Features not explicitly listed in the current phase are FORBIDDEN. Future phases exist for context only.

**Current Phase: PHASE 3 (Visual Intelligence)**

See Phase Roadmap section below for complete phase definitions.

**Scope Management Requirements:**

- **Current phase scope is law**: Only features in the active phase are permitted.
- **Out-of-scope features FORBIDDEN**: Features from future phases MUST NOT be implemented.
- **No premature optimization**: Do NOT build abstractions for future phases.
- **Future phases are REFERENCE ONLY**: Provides context but MUST NOT be implemented.
- **Feature additions require explicit approval**: Any feature not in current phase requires constitution amendment.
- **Phase completion criteria**: All features in phase MUST be shipped before advancing.

**Rationale**: Scope creep kills projects. Shipping a polished, focused phase is better than a bloated, unfinished product.

**Validation**: Code reviews MUST reject any code implementing out-of-scope features.

---

## Phase Roadmap

### Phase 1: MVP Foundation ✅ COMPLETE
**Status**: Shipped
**Duration**: Completed November 2025

**Delivered Features:**
- ✅ Watchlist (search, add coins, price display, 24h change, 30-second polling)
- ✅ Portfolio (manual transactions, holdings list, P&L calculations)
- ✅ Transaction management (add, edit, delete with confirmation)
- ✅ Realized vs Unrealized P&L separation
- ✅ Closed positions tracking
- ✅ Empty states (watchlist and portfolio)
- ✅ Form validation (overselling prevention)
- ✅ "Sell All" shortcut

**Success Criteria Met:**
- ✅ Core functionality complete
- ✅ P&L calculations accurate
- ✅ 60fps scrolling performance
- ✅ Ready for TestFlight

---

### Phase 2: Widgets ✅ COMPLETE
**Status**: Shipped
**Duration**: Completed December 2025
**Goal**: Create daily habit through glanceability

**Delivered Features:**

**2.1 Home Screen Widgets:**
- ✅ Small widget (systemSmall): Portfolio value, total P&L, update timestamp
- ✅ Medium widget (systemMedium): Portfolio value, P&L breakdown, top 2 holdings
- ✅ Large widget (systemLarge): Portfolio value, P&L breakdown, top 5 holdings
- ✅ App Groups for shared data access
- ✅ 30-minute timeline refresh
- ✅ Offline support with cached data
- ✅ Deep link to Portfolio tab on tap
- ✅ Empty state when no holdings
- ✅ Light/Dark mode support

**2.2 Widget Infrastructure:**
- ✅ Shared data layer between app and widget
- ✅ Background price fetching for widget
- ✅ Cache management for offline display
- ✅ Error handling (show cached data on failure)

**Success Criteria Met:**
- ✅ All 3 widget sizes render correctly
- ✅ Widget values match main app exactly
- ✅ Updates occur every 30 minutes
- ✅ Offline shows cached data gracefully
- ✅ No crashes in any edge case

---

### Phase 3: Visual Intelligence 🔵 ACTIVE
**Status**: In Development
**Target Duration**: 4-6 weeks
**Goal**: Make data actionable, increase daily engagement

**Scope (ACTIVE - Implementation Permitted):**
- [ ] Price charts per coin (1D, 1W, 1M, 1Y)
- [ ] Portfolio value over time chart
- [ ] Price alerts (push notifications)
- [ ] Best/worst performers view
- [ ] Portfolio allocation breakdown

**Dependencies**: Phase 2 complete ✅

---

### Phase 4: Monetization ⚪ PLANNED
**Status**: Not Started
**Target Duration**: 3-4 weeks
**Goal**: Generate sustainable revenue

**Planned Scope:**
- Pro tier subscription ($4.99/month or $39/year)
- Tax export feature (CSV, capital gains report)
- Unlimited price alerts (free tier = 3)
- Multiple portfolios (free tier = 1)
- Advanced chart features
- 15-minute widget updates (free = 30min)
- Per-transaction realized gain display in transaction history

**Monetization Philosophy:**
- Widgets remain FREE (growth driver)
- Monetize pain points (taxes, alerts)
- Clear value proposition for Pro tier

**Dependencies**: Phase 3 complete, user base established

---

### Phase 5: Data Expansion ⚪ PLANNED
**Status**: Not Started
**Target Duration**: 4-6 weeks
**Goal**: Reduce manual entry friction

**Planned Scope:**
- Exchange API integration (Coinbase, Binance read-only)
- Auto-import transactions
- Wallet connection (Ethereum, read-only)
- Background app refresh
- Lock screen widgets

**Dependencies**: Phase 4 complete, monetization validated

---

### Phase 6: Growth & Retention ⚪ PLANNED
**Status**: Not Started
**Target Duration**: 3-4 weeks
**Goal**: Organic growth, reduce churn

**Planned Scope:**
- Portfolio insights ("Your BTC is up 12% this month")
- Share portfolio performance (privacy-safe)
- Market comparison (vs BTC, S&P 500)
- Siri shortcuts
- Advanced widgets (StandBy mode)

**Dependencies**: Phase 5 complete, 10K+ users

---

## Widget-Specific Standards

### Widget Performance Requirements

- **Timeline refresh**: Every 30 minutes maximum. More frequent refreshes are FORBIDDEN.
- **Background fetch efficiency**: Fetch only coins user owns. Fetching all coins is FORBIDDEN.
- **Cached data display**: Always show cached data when API unavailable. Blank widgets are FORBIDDEN.
- **Memory footprint**: Widget extension MUST stay under 30MB memory.

### Widget Design Requirements

- **System backgrounds**: Use `containerBackground` with system materials.
- **Consistent with main app**: Colors, typography, spacing MUST match main app.
- **Readable at glance**: Most important info (portfolio value) MUST be largest.
- **Update timestamp**: Always show when data was last refreshed.
- **Graceful degradation**: Offline state MUST be visually distinct but not alarming.

### Widget Data Sharing

- **App Groups required**: Shared container for Swift Data access.
- **Calculation reuse**: P&L logic MUST be shared code (no duplication).
- **Cache invalidation**: Widget cache invalidates when main app updates transactions.

---

## Development Standards

### Code Style

- **Swift 6.0 features**: Use strict concurrency checking and modern Swift features.
- **Swift API Design Guidelines**: Follow official Apple Swift API Design Guidelines.
- **async/await over completion handlers**: Modern concurrency patterns only.
- **Functions under 30 lines**: Keep functions focused and readable.
- **No force unwrapping**: Use `guard` or `if let`. Force unwrapping is FORBIDDEN except in tests.
- **Typed errors**: Define custom error types conforming to `LocalizedError`.

### File Organization

- **Feature folders**: Organize by feature (`Features/Watchlist/`, `Features/Portfolio/`, `Features/Widget/`).
- **Widget extension**: Separate target in `BitpalWidget/` directory.
- **Shared code**: Common code in `Shared/` accessible by both app and widget.
- **Naming conventions**:
  - Views: `WatchlistView.swift`
  - ViewModels: `WatchlistViewModel.swift`
  - Services: `CoinGeckoService.swift`
  - Models: `Coin.swift`, `Transaction.swift`
  - Widgets: `PortfolioWidget.swift`, `PortfolioWidgetView.swift`
  - Extensions: `View+Extensions.swift`

### Logging

- **Unified logging**: Use `OSLog` with categorized loggers (`.api`, `.persistence`, `.ui`, `.widget`).
- **Performance signposts**: Use `OSSignposter` for Instruments profiling.
- **Widget logging**: Log timeline refreshes and data fetch success/failure.

---

## Testing Strategy

**Test where valuable, skip where manual testing suffices.**

### Tests REQUIRED

1. **Transaction calculations**: Holdings, average cost, P&L (existing)
2. **API response parsing**: CoinGecko API decoding (existing)
3. **Swift Data operations**: Transaction CRUD (existing)
4. **Widget data provider**: Timeline generation, data transformation
5. **Shared calculation logic**: Verify widget uses same calculations as app

### Tests OPTIONAL

- SwiftUI views (visual review)
- Widget visual appearance (manual review)
- Simple getters/setters

### Testing Tools

- **XCTest**: Unit and integration tests
- **Xcode Instruments**: Performance profiling
- **Widget preview**: Use Xcode canvas for widget development
- **Manual testing**: UI flows, widget placement, edge cases

---

## Governance

### Amendment Process

1. **Identify need**: Document why constitution change is required
2. **Propose amendment**: Draft specific changes with rationale
3. **Impact analysis**: Identify affected code, templates, dependencies
4. **Version bump**: Semantic versioning:
   - **MAJOR**: Phase transitions, principle changes
   - **MINOR**: New standards, expanded guidance
   - **PATCH**: Clarifications, typo fixes
5. **Update sync impact report**: Document version change
6. **Update dependent files**: CLAUDE.md, templates
7. **Commit**: Format `docs: amend constitution to vX.Y.Z (description)`

### Phase Transition Process

1. **Verify current phase complete**: All features shipped, success criteria met
2. **Document completion**: Update phase status to ✅ COMPLETE
3. **Activate next phase**: Update status to 🔵 ACTIVE
4. **Major version bump**: Phase transitions are MAJOR version changes
5. **Update CLAUDE.md**: Reflect new active phase
6. **Communicate**: Note phase transition in commit message

### Compliance Review

- **All PRs MUST verify compliance** with constitution principles
- **Code reviews MUST reject** violations of NON-NEGOTIABLE principles
- **Performance checks MUST occur** before merging (Instruments)
- **Scope violations MUST be rejected** immediately
- **Widget values MUST match** main app exactly

### Constitution Authority

- **Constitution supersedes all other guidance**
- **CLAUDE.md provides context**, constitution provides governance
- **When in doubt, consult constitution first**
- **Phase scope is absolute**: No exceptions without amendment

---

## Success Milestones

### 6-Month Targets

| Milestone | Target | Metric |
|-----------|--------|--------|
| Month 1 | Phase 1 shipped | TestFlight live ✅ |
| Month 2 | Phase 2 shipped | Widgets in App Store |
| Month 3 | Phase 3 shipped | Charts + alerts live |
| Month 4 | First revenue | $100 MRR |
| Month 5 | User growth | 1,000 downloads |
| Month 6 | Sustainable | $500 MRR |

### 12-Month Vision

- 20,000 downloads
- $2,000 MRR
- "Best iOS crypto widgets" reputation
- 4.5+ App Store rating

---

**Version**: 3.0.0
**Ratified**: 2025-11-08
**Last Amended**: 2025-12-01
**Current Phase**: Phase 3 (Visual Intelligence)