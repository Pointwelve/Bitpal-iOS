<!--
=============================================================================
SYNC IMPACT REPORT - Constitution v1.0.0
=============================================================================

VERSION CHANGE: New → 1.0.0 (initial ratification)

PRINCIPLES DEFINED (5 total):
  I.   Performance-First Architecture (NON-NEGOTIABLE)
  II.  Liquid Glass Design System
  III. MVVM + Modern Swift Patterns
  IV.  Data Integrity & Calculation Accuracy
  V.   Phase Discipline (Scope Management)

SECTIONS ADDED:
  - Core Principles (5 principles)
  - Development Standards
  - Testing Strategy
  - Governance

TEMPLATES REQUIRING UPDATES:
  ✅ .specify/templates/plan-template.md - Constitution Check updated
  ✅ .specify/templates/spec-template.md - Phase scope alignment verified
  ✅ .specify/templates/tasks-template.md - Testing strategy aligned

FOLLOW-UP TODOS: None (all placeholders filled)

RATIONALE FOR v1.0.0:
  - Initial ratification of project constitution
  - Defines complete governance framework for Phase 1 MVP
  - Establishes non-negotiable performance and scope constraints

=============================================================================
-->

# Bitpal iOS Constitution

## Core Principles

### I. Performance-First Architecture (NON-NEGOTIABLE)

**Performance is the core differentiator.** Every architectural decision, every line of code, every feature MUST prioritize smoothness and responsiveness. Laggy experiences are FORBIDDEN.

**Mandatory Performance Requirements:**

- **60fps UI smoothness**: All list scrolling, animations, and interactions MUST maintain 60fps minimum on iPhone 13 and newer devices.
- **Throttled updates**: Price updates occur at 30-second intervals. Real-time updates are FORBIDDEN (waste resources, drain battery).
- **Two-tier caching**: Implement in-memory cache (fast reads) + Swift Data cache (persistent). Cache MUST be invalidated explicitly.
- **Batch API requests**: Multiple coin prices fetched in single requests. Individual requests per coin are FORBIDDEN.
- **LazyVStack for lists**: Lists with >10 items MUST use LazyVStack. Regular VStack is FORBIDDEN for long lists.
- **Non-blocking async operations**: UI updates MUST occur on MainActor. Blocking the main thread is FORBIDDEN.
- **Cached computed values**: Expensive calculations (P&L totals, portfolio values) MUST be cached with explicit invalidation.

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

**Rationale**: Platform consistency reduces development time, ensures accessibility, and provides users with familiar interaction patterns. Custom designs that violate iOS conventions are FORBIDDEN in Phase 1.

**Validation**: Visual review against iOS 26 HIG. All interactive elements MUST meet minimum tap target sizes.

---

### III. MVVM + Modern Swift Patterns

**Use lightweight MVVM architecture with modern Swift patterns.** Avoid over-engineering and heavy frameworks.

**Architectural Requirements:**

- **@Observable macro**: ViewModels MUST use `@Observable` (Swift 5.9+). ObservableObject is FORBIDDEN.
- **SwiftUI views are stateless**: Views are pure, declarative, and contain NO business logic. Logic goes in ViewModels.
- **ViewModels contain business logic**: Handle user actions, update state, coordinate with services.
- **Services are singletons**: API client, persistence manager, price update service use singleton pattern for shared state.
- **Swift Data for persistence**: Use Swift Data (modern replacement for Core Data). Core Data is FORBIDDEN.
- **async/await for concurrency**: Use modern async/await. Combine publishers are FORBIDDEN.
- **Structs over classes**: Prefer structs unless reference semantics are required. Use `final class` when classes necessary.
- **No external dependencies**: URLSession, Swift Data, SwiftUI are sufficient. Third-party frameworks are FORBIDDEN for Phase 1 MVP.

**Rationale**: Modern Swift patterns reduce boilerplate, improve compile times, and align with platform direction. TCA and other heavy frameworks add complexity without value for MVP scope.

**Validation**: Code reviews MUST verify @Observable usage, stateless views, and no external dependencies.

---

### IV. Data Integrity & Calculation Accuracy

**Financial calculations MUST be accurate and verifiable.** User trust depends on correct P&L calculations.

**Data Integrity Requirements:**

- **Decimal type for money**: Use `Decimal` type for all prices, quantities, and calculations. Double and Float are FORBIDDEN for financial values.
- **P&L calculations tested**: Transaction calculations, average cost, profit/loss MUST have unit tests before implementation.
- **Independently verifiable**: Users can manually verify P&L calculations from transaction history.
- **Cached computed values**: Portfolio totals and P&L cached with explicit invalidation when transactions change.
- **API response parsing validated**: CoinGecko API responses MUST be parsed defensively with error handling.
- **Proper transaction accounting**: Buy transactions add to holdings, Sell transactions reduce holdings. Average cost calculation MUST follow standard accounting principles.

**Rationale**: Financial apps live or die by accuracy. A single incorrect P&L calculation destroys user trust permanently.

**Validation**: Unit tests for all calculation logic. Manual verification of P&L against sample transactions.

---

### V. Phase Discipline (Scope Management)

**Phase 1 scope is FROZEN.** Features not explicitly listed in Phase 1 are FORBIDDEN. Future phases exist for context only.

**Scope Management Requirements:**

- **Phase 1 scope is law**: Only Watchlist and Manual Portfolio features are permitted. See CLAUDE.md for complete Phase 1 definition.
- **Out-of-scope features FORBIDDEN**: The following are explicitly FORBIDDEN in Phase 1:
  - Wallet integration
  - Multiple portfolios
  - Charts or graphs
  - Price alerts/notifications
  - Widgets
  - Ads or monetization
  - Social features
  - News feeds
  - iCloud sync
  - Export functionality
  - Biometric authentication
- **No premature optimization**: Do NOT build abstractions for future phases. Optimize for current requirements only.
- **Future phases are REFERENCE ONLY**: Phase 2/3/4 documentation provides context for architectural decisions but MUST NOT be implemented.
- **Feature additions require explicit approval**: Any feature not in Phase 1 scope requires documented approval and constitution amendment.

**Rationale**: Scope creep kills MVPs. Shipping a polished, focused Phase 1 is better than a bloated, unfinished product. Every out-of-scope feature delays launch.

**Validation**: Code reviews MUST reject any code implementing out-of-scope features. Every feature MUST map to Phase 1 requirements in CLAUDE.md.

---

## Development Standards

### Code Style

- **Swift 6.0 features**: Use strict concurrency checking and modern Swift features.
- **Swift API Design Guidelines**: Follow official Apple Swift API Design Guidelines.
- **async/await over completion handlers**: Modern concurrency patterns only.
- **Functions under 30 lines**: Keep functions focused and readable.
- **No force unwrapping**: Use `guard` or `if let`. Force unwrapping (`!`) is FORBIDDEN except in testing.
- **Typed errors**: Define custom error types conforming to `LocalizedError` for user-facing errors.

### File Organization

- **Feature folders**: Organize by feature (`Features/Watchlist/`, `Features/Portfolio/`).
- **Naming conventions**:
  - Views: `WatchlistView.swift`
  - ViewModels: `WatchlistViewModel.swift`
  - Services: `CoinGeckoService.swift`
  - Models: `Coin.swift`, `Transaction.swift`
  - Extensions: `View+Extensions.swift`

### Logging

- **Unified logging**: Use `OSLog` with categorized loggers (`.api`, `.persistence`, `.ui`).
- **Performance signposts**: Use `OSSignposter` for Instruments profiling of critical paths.

---

## Testing Strategy

**Test where valuable, skip where manual testing suffices.**

### Tests REQUIRED

The following areas MUST have unit tests written BEFORE implementation (test-first):

1. **Transaction calculations**: Holdings computation, average cost, profit/loss, profit/loss percentage
2. **API response parsing**: CoinGecko API response decoding and error handling
3. **Swift Data operations**: Critical persistence operations (transaction creation, deletion)
4. **Price update logic**: Throttling, batching, cache invalidation

### Tests OPTIONAL

The following areas MAY be tested manually:

- SwiftUI views (visual review sufficient)
- Simple getters/setters
- Straightforward UI flows
- Navigation logic

### Testing Tools

- **XCTest**: Unit and integration tests
- **Xcode Instruments**: Performance profiling (Time Profiler, Allocations, Network)
- **Manual testing**: UI flows, visual design, edge cases

**Rationale**: Focus testing effort on critical business logic where bugs have financial impact. UI testing provides diminishing returns for MVP.

---

## Governance

### Amendment Process

1. **Identify need**: Document why constitution change is required
2. **Propose amendment**: Draft specific changes with rationale
3. **Impact analysis**: Identify affected code, templates, and dependencies
4. **Version bump**: Follow semantic versioning:
   - **MAJOR**: Backward incompatible changes (principle removal/redefinition)
   - **MINOR**: New principle or materially expanded guidance
   - **PATCH**: Clarifications, wording fixes, non-semantic refinements
5. **Update sync impact report**: Document version change and affected files
6. **Update dependent templates**: Ensure plan-template.md, spec-template.md, tasks-template.md stay consistent
7. **Commit**: Use format `docs: amend constitution to vX.Y.Z (description)`

### Compliance Review

- **All PRs MUST verify compliance** with constitution principles
- **Code reviews MUST reject** violations of NON-NEGOTIABLE principles
- **Performance checks MUST occur** before merging features (Instruments profiling)
- **Scope violations MUST be rejected** immediately
- **Complexity MUST be justified** against constitution constraints

### Constitution Authority

- **Constitution supersedes all other guidance** in case of conflict
- **CLAUDE.md provides context**, constitution provides governance
- **When in doubt, consult constitution first**

---

**Version**: 1.0.0
**Ratified**: 2025-11-08
**Last Amended**: 2025-11-08
