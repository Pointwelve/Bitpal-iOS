# Bitpal iOS

A sophisticated cryptocurrency price tracking and monitoring application for iOS, providing real-time market data, price alerts, and watchlist management functionality.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Core Components](#core-components)
- [API Integration](#api-integration)
- [Development Guide](#development-guide)
- [Testing](#testing)
- [Build & Deployment](#build--deployment)
- [Contributing](#contributing)
- [License](#license)

## Overview

Bitpal is a comprehensive cryptocurrency market monitoring application that enables users to track real-time prices across multiple exchanges, set custom price alerts, and manage personalized watchlists. Built with modern iOS development practices, the app features a clean architecture, reactive programming patterns, and a polished user interface.

### Key Highlights

- **Real-time price streaming** via WebSocket connections
- **Multi-exchange support** for comprehensive market coverage
- **Price alerts** with push notification support
- **Today Widget** for quick price checks
- **Clean MVVM-C architecture** with RxSwift
- **100% programmatic UI** without storyboards
- **Comprehensive test coverage** across all layers

## Features

### 1. Watchlist Management
- Create and manage personalized cryptocurrency watchlists
- Real-time price updates with visual change indicators
- Drag-and-drop reordering
- Swipe-to-delete functionality
- 3D Touch support for quick previews
- Pull-to-refresh for manual updates

### 2. Real-Time Price Streaming
- WebSocket-based live price updates
- Current price, bid/ask spreads, and volume data
- 24-hour and hourly price change percentages
- High/low price tracking
- Automatic reconnection handling

### 3. Price Alerts
- Create custom price alerts with comparison operators (≤, ≥)
- Enable/disable alerts without deletion
- Push notification delivery
- Alert management with intuitive UI

### 4. Detailed Market Data
- Interactive price charts (line and candlestick)
- Multiple time periods (1H, 1D, 1W, 1M, 1Y)
- Volume information and market statistics
- Exchange-specific data comparison

### 5. Today Widget Extension
- Compact watchlist view in iOS widgets
- Quick price updates without opening the app
- Direct navigation to main app

### 6. Additional Features
- Multi-language support (English, Japanese, Korean, Chinese)
- Light/Dark theme support
- Offline data caching
- Secure authentication
- Analytics and crash reporting

## Architecture

Bitpal follows a clean, modular architecture with clear separation of concerns:

### Layer Structure

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│         (ViewControllers, ViewModels, Views)              │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                         │
│      (Use Cases, Entities, Repository Interfaces)        │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                          │
│    (Repositories, Network, Storage, Data Sources)        │
└─────────────────────────────────────────────────────────┘
```

### Design Patterns

- **MVVM-C (Model-View-ViewModel-Coordinator)**: UI architecture pattern
- **Repository Pattern**: Data access abstraction
- **Use Case Pattern**: Business logic encapsulation
- **Dependency Injection**: Loose coupling between components
- **Reactive Programming**: RxSwift for data flow and event handling

## Requirements

- **iOS Deployment Target**: iOS 12.0+
- **Xcode Version**: 11.5+
- **Swift Version**: 5.0+
- **macOS**: 10.15+ (for development)

## Dependencies

### Core Dependencies

- **RxSwift** (~> 5.1): Reactive programming
- **RxCocoa**: Reactive extensions for Cocoa
- **Alamofire**: HTTP networking
- **Realm** (~> 5.4): Local database
- **Charts** (~> 3.5): Interactive charts
- **SocketIO** (~> 15.2): WebSocket client

### UI/UX Dependencies

- **SwipeCellKit** (~> 2.6): Swipeable table cells
- **NVActivityIndicatorView** (~> 5.0): Loading indicators
- **SwiftReorder** (~> 7.2): Table view reordering
- **Presentr** (~> 1.9): Modal presentations
- **Siren** (~> 5.4): App update notifications

### Firebase Services

- Firebase Analytics
- Firebase Auth
- Firebase Crashlytics
- Firebase Messaging
- Firebase Performance

### Development Tools

- **Carthage**: Dependency management
- **XcodeGen**: Project file generation
- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Code formatting
- **Sourcery**: Code generation

## Installation

### Prerequisites

1. Install Homebrew (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install required tools:
```bash
brew bundle
```

### Setup Steps

1. Clone the repository:
```bash
git clone https://github.com/your-org/Bitpal-iOS.git
cd Bitpal-iOS
```

2. Install dependencies:
```bash
carthage bootstrap --platform iOS --cache-builds
```

3. Generate Xcode project:
```bash
xcodegen generate
```

4. Configure Firebase:
   - Place your `GoogleService-Info.plist` in the `Firebase/` directory
   - Ensure the file is properly encrypted if storing in version control

5. Open the project:
```bash
open Bitpal.xcodeproj
```

## Project Structure

```
Bitpal-iOS/
├── Sources/
│   ├── Bitpal/              # Main app target
│   │   ├── Infrastructure/  # App setup and configuration
│   │   ├── Model/          # App-specific models
│   │   ├── Resources/      # Assets, fonts, strings
│   │   └── UI/            # ViewControllers and Views
│   ├── Domain/             # Business logic layer
│   │   ├── Entity/        # Core business entities
│   │   ├── UseCase/       # Business use cases
│   │   └── Repository/    # Repository interfaces
│   ├── Data/              # Data access layer
│   │   ├── Network/       # API clients
│   │   ├── Storage/       # Local persistence
│   │   └── Repository/    # Repository implementations
│   ├── Widget/            # Today widget extension
│   └── Notification Service Extension/
├── Tests/                 # Unit and integration tests
├── Configuration/         # App configuration files
├── fastlane/             # Automation scripts
└── project.yml           # XcodeGen configuration
```

## Core Components

### 1. Network Layer

**API Client Architecture:**
- `RestAPIClient`: RESTful API communication
- `SocketClient`: WebSocket connections
- `SessionManager`: Request configuration
- SSL certificate pinning support

**Key Endpoints:**
- Price data: `/data/pricemulti`, `/data/pricemultifull`
- Historical data: `/data/histominute`, `/data/histohour`, `/data/histoday`
- Internal API: Authentication, alerts, watchlist management

### 2. Data Persistence

**Realm Database Schema:**
- `CurrencyDetailRealm`: Cached currency information
- `AlertRealm`: User price alerts
- `CurrencyPairRealm`: Watchlist items
- `HistoricalPriceRealm`: Chart data cache

**Other Storage:**
- `UserDefaults`: User preferences
- `Keychain`: Secure credentials
- `iCloud`: User identifier sync

### 3. Use Cases

Core business logic implementations:
- `StreamPriceUseCaseCoordinator`: Real-time price streaming
- `AlertUseCaseCoordinator`: Alert management
- `WatchlistUseCaseCoordinator`: Watchlist operations
- `AuthenticationUseCaseCoordinator`: User authentication

### 4. UI Components

**View Controllers:**
- `WatchlistViewController`: Main watchlist screen
- `WatchlistDetailViewController`: Currency pair details
- `AlertsViewController`: Alert management
- `CreatePriceAlertViewController`: Alert creation

**Custom Views:**
- `LoadStateView`: Loading/empty/error states
- `ChartView`: Interactive price charts
- `WatchlistTableViewCell`: Currency row display

## API Integration

### External APIs

**CryptoCompare API:**
- Base URL: Configured via `Configuration.plist`
- Authentication: API key in request parameters
- Rate limiting: Handled automatically

### Internal API

**Authentication:**
- Bearer token-based authentication
- Device fingerprint for anonymous users
- Automatic token refresh

**WebSocket Connection:**
```swift
// Subscription format
"SubAdd~{exchange}~{baseCurrency}~{quoteCurrency}"

// Price update format
{
  "TYPE": "2",
  "MARKET": "Binance",
  "FROMSYMBOL": "BTC",
  "TOSYMBOL": "USD",
  "PRICE": 50000.00,
  ...
}
```

## Development Guide

### Setting Up Development Environment

1. **Configure Git Hooks:**
```bash
./scripts/setup-git-hooks.sh
```

2. **Install Development Certificates:**
```bash
fastlane match development
```

3. **Configure IDE:**
   - Enable SwiftLint in Xcode
   - Configure code formatting on save

### Code Style Guidelines

- Follow Swift API Design Guidelines
- Use SwiftLint rules defined in `.swiftlint.yml`
- Maintain consistent code formatting with SwiftFormat
- Write self-documenting code with clear naming

### Adding New Features

1. **Domain Layer:**
   - Define entities in `Domain/Entity/`
   - Create use case in `Domain/UseCase/`
   - Define repository interface

2. **Data Layer:**
   - Implement repository in `Data/Repository/`
   - Add network endpoints if needed
   - Create storage implementation

3. **Presentation Layer:**
   - Create ViewModel with Input/Output pattern
   - Implement ViewController
   - Add navigation in appropriate Navigator

### Debugging

**Network Debugging:**
```swift
// Enable network logging
#if DEBUG
    NetworkActivityLogger.shared.level = .debug
    NetworkActivityLogger.shared.startLogging()
#endif
```

**Realm Database Inspection:**
- Use Realm Studio to inspect `.realm` files
- Located at: `~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/`

## Testing

### Running Tests

**All Tests:**
```bash
fastlane test
```

**Specific Target:**
```bash
xcodebuild test -scheme Domain -destination 'platform=iOS Simulator,name=iPhone 12'
```

### Test Structure

- **DomainTests**: Business logic and entity tests
- **DataTests**: Repository and network tests
- **BitpalTests**: UI and integration tests

### Test Coverage

- Aim for >80% code coverage
- Focus on critical business logic
- Test error scenarios and edge cases

## Build & Deployment

### Build Configurations

- **Debug**: Development builds with debugging enabled
- **Release**: Production builds with optimizations

### Fastlane Actions

```bash
# Run tests
fastlane test

# Build for development
fastlane build_development

# Build for TestFlight
fastlane beta

# Build for App Store
fastlane release
```

### Continuous Integration

The project supports CI/CD pipelines with:
- Automated testing on pull requests
- Beta distribution via TestFlight
- Automated App Store submissions

### Code Signing

- Managed via Fastlane Match
- Certificates stored in encrypted Git repository
- Automatic provisioning profile management

## Contributing

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style and patterns
- Write unit tests for new functionality
- Update documentation as needed
- Ensure all tests pass before submitting PR
- Include detailed PR description

### Code Review Process

1. Automated checks (tests, linting)
2. Peer review by team members
3. Address feedback and suggestions
4. Merge after approval

## Troubleshooting

### Common Issues

**Carthage Build Failures:**
```bash
# Clear Carthage cache
rm -rf ~/Library/Caches/org.carthage.CarthageKit
carthage bootstrap --platform iOS --cache-builds
```

**XcodeGen Issues:**
```bash
# Regenerate project
rm -rf Bitpal.xcodeproj
xcodegen generate
```

**Realm Migration:**
- Check `RealmManager` for migration blocks
- Increment schema version when changing models

## License

This project is proprietary software owned by Pointwelve Pte. Ltd. All rights reserved.

---

For additional support or questions, please contact the development team.