# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Bitpal iOS** is a sophisticated cryptocurrency price tracking and portfolio management application with **two implementations**:

1. **Legacy (Production)**: UIKit + RxSwift + Clean Architecture in `/Legacy/`
2. **Modern (v2)**: SwiftUI + SwiftData + @Observable pattern in `/Bitpal-v2/`

**Current Development Focus**: The SwiftUI v2 implementation targeting iOS 18+ with modern patterns.

## Build Commands

### Xcode Project
```bash
# Open the SwiftUI v2 project
open Bitpal-v2/Bitpal-v2.xcodeproj

# Build from command line
xcodebuild -project Bitpal-v2/Bitpal-v2.xcodeproj -scheme Bitpal-v2 -configuration Debug build

# Run tests
xcodebuild test -project Bitpal-v2/Bitpal-v2.xcodeproj -scheme Bitpal-v2 -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Individual Test Execution
```bash
# Run specific test class
xcodebuild test -project Bitpal-v2/Bitpal-v2.xcodeproj -scheme Bitpal-v2 -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Bitpal-v2Tests/VerySimpleTests

# Run specific test method
xcodebuild test -project Bitpal-v2/Bitpal-v2.xcodeproj -scheme Bitpal-v2 -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Bitpal-v2Tests/VerySimpleTests/testCurrencyCreation
```

## Architecture Overview

### SwiftUI v2 Architecture (Current Focus)

**Pattern**: MVVM + @Observable + SwiftData + Coordinator Pattern

**Key Components**:
- **AppCoordinator**: Singleton managing all services and SwiftData container
- **Services**: Reactive services for price streaming, alerts, technical analysis
- **SwiftData Models**: Modern data persistence with @Model macro
- **@Observable ViewModels**: State management with @Observable pattern
- **Feature-Based Structure**: Organized by user-facing features

**Core Services (Environment Injected)**:
- `PriceStreamService`: WebSocket price streaming via CoinDesk API
- `AlertService`: Price alert management with local notifications
- `CurrencySearchService`: Currency search and discovery
- `TechnicalAnalysisService`: Market analysis and indicators
- `HistoricalDataService`: Historical price data management

### Data Flow
1. **AppCoordinator** initializes all services and SwiftData container
2. **Services** injected into SwiftUI environment at app level
3. **ViewModels** access services via environment and manage view state
4. **SwiftData** handles persistence with automatic view updates
5. **WebSocket** streams real-time prices to UI automatically

### SwiftData Models
```swift
// Core entities with @Model macro
@Model class CurrencyPair { }
@Model class Currency { }
@Model class Exchange { }
@Model class Alert { }
@Model class HistoricalPrice { }
@Model class Configuration { }
@Model class Watchlist { }
```

## Key Development Patterns

### Service Integration
Services are environment-injected at app level and accessed in views:
```swift
@Environment(PriceStreamService.self) private var priceStreamService
@Environment(AlertService.self) private var alertService
```

### ViewModel Pattern
ViewModels use @Observable and receive ModelContext:
```swift
@MainActor
@Observable
final class SomeViewModel {
    func setModelContext(_ context: ModelContext) {
        // Set context for data operations
    }
}
```

### Real-Time Updates
- WebSocket streaming via `PriceStreamService.shared`
- SwiftData automatically updates UI when models change
- Subscribe/unsubscribe pattern for price streaming

## Project Structure

### `/Bitpal-v2/Bitpal-v2/` (Active Development)
- **Core/**: Foundational architecture
  - `App/`: AppCoordinator and app-level setup
  - `Architecture/`: Reactive patterns and protocols
  - `Models/`: SwiftData model definitions
  - `Network/`: API clients, WebSocket, caching
  - `Services/`: Business logic services
- **Features/**: Feature-based organization
  - `Watchlist/`: Currency tracking and management
  - `Alerts/`: Price alert system
  - `Portfolio/`: Holdings and transaction management
  - `Charts/`: Interactive price charts
  - `CurrencyDetail/`: Detailed currency information
  - `Search/`: Currency search and discovery

### `/Legacy/` (Reference Implementation)
Complete UIKit + RxSwift production app with:
- Clean Architecture (Domain/Data/UI layers)
- MVVM-C pattern with Coordinators
- Realm database persistence
- Comprehensive test coverage
- Today Widget and Notification Service extensions

## API Configuration

The app uses **CoinDesk API** for market data:
- **Host**: `https://data-api.coindesk.com`
- **API Key**: Configured in `Configuration` model
- **WebSocket**: Real-time price streaming
- **Rate Limiting**: Built-in exponential backoff

## Testing Strategy

### Current Test Structure
- **Bitpal-v2Tests/**: Basic XCTest setup
- **Bitpal-v2UITests/**: UI automation tests
- **VerySimpleTests.swift**: Core model validation

### Test Execution
Tests validate core models (Currency, Exchange, Configuration) and basic functionality.

## Feature Implementation Status

### ✅ Implemented (v2)
- Basic watchlist with SwiftData persistence
- Real-time price streaming (CoinDesk WebSocket)
- Price alerts with local notifications
- Interactive charts with multiple timeframes
- Currency detail views with market data
- Portfolio management (basic)
- Currency search functionality

### ❌ Critical Gaps (Reference features.md)
- **Widget System**: No WidgetKit widgets or Live Activities
- **Firebase Authentication**: Missing user management
- **Testing Infrastructure**: Limited test coverage
- **Advanced Charts**: No candlestick charts or advanced features
- **Deep Linking**: No URL schemes or navigation routing
- **Background Processing**: No silent notifications

## Development Notes

### Working with SwiftData
- Models automatically persist when inserted into ModelContext
- UI updates automatically when @Model properties change
- Use `@Query` in SwiftUI views for reactive data fetching

### WebSocket Management
- `PriceStreamService` handles all WebSocket connections
- Subscribe/unsubscribe to individual currency pairs
- Automatic reconnection with exponential backoff

### Service Architecture
- Services are singletons shared across the app
- ModelContext injection pattern for data access
- Environment injection for SwiftUI integration

### Performance Considerations
- SwiftData queries are automatically optimized
- WebSocket subscriptions only for active/visible currencies
- Lazy loading for historical data and charts

## Common Development Tasks

When adding new features:
1. Create SwiftData models in `Core/Models/`
2. Implement business logic in `Core/Services/`
3. Build UI in feature-specific directories under `Features/`
4. Inject services via environment in `Bitpal_v2App.swift`
5. Write tests in `Bitpal-v2Tests/`

When debugging WebSocket issues:
- Check `PriceStreamService` connection state
- Verify API key configuration in `Configuration` model
- Monitor console for WebSocket connection logs

## Migration Context

The Legacy implementation provides reference patterns for:
- Complex navigation (Navigator pattern)
- Comprehensive testing (multi-layer test coverage)
- Widget implementation (Today Extension)
- Firebase integration (authentication, analytics)
- Advanced UI components (3D Touch, swipe actions)

Use Legacy code as architectural reference while implementing modern SwiftUI equivalents.