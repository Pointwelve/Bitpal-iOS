# Bitpal iOS - Complete SwiftUI Migration Plan & Implementation Guide

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Strategy](#migration-strategy)
3. [Project Setup](#project-setup)
4. [Architecture Design](#architecture-design)
5. [Implementation Phases](#implementation-phases)
6. [Detailed Implementation Guide](#detailed-implementation-guide)
7. [Testing Strategy](#testing-strategy)
8. [Migration Patterns](#migration-patterns)
9. [Risk Management](#risk-management)
10. [Timeline & Resources](#timeline--resources)

## Executive Summary

This document provides a complete guide for rebuilding the Bitpal iOS cryptocurrency tracking application using SwiftUI, replacing the current UIKit-based implementation while maintaining all functionality and improving the architecture.

### Current State vs Target State

| Aspect | Current | Target |
|--------|---------|---------|
| UI Framework | UIKit (Programmatic) | SwiftUI 6.0 |
| Architecture | MVVM-C with RxSwift | MVVM with Observation + Combine |
| Min iOS Version | 12.0 | 18.0+ |
| Dependency Manager | Carthage | Swift Package Manager |
| Persistence | Realm | SwiftData |
| Networking | Alamofire + SocketIO | URLSession + WebSocket |
| Charts | Charts (Daniel Gindi) | Swift Charts 6.0 |
| Concurrency | Completion Handlers | Swift 6 Concurrency |
| State Management | RxSwift Subjects | @Observable + @State |
| Navigation | Coordinator Pattern | NavigationStack + NavigationPath |
| Widgets | Today Extension | WidgetKit + App Intents |

### Key Benefits
- **iOS 18 Native Features**: Interactive widgets, Control Center integration, refined animations
- **SwiftUI 6.0**: Enhanced performance, new view modifiers, improved state management
- **Swift 6 Concurrency**: Complete data race safety, improved async/await patterns
- **SwiftData**: Modern Core Data replacement with better SwiftUI integration
- **@Observable Macro**: Simplified state management replacing ObservableObject
- **App Intents**: Deep Siri integration and Shortcuts support
- **Control Center Controls**: Quick price checking without opening app
- **Live Activities**: Real-time price updates on Lock Screen and Dynamic Island
- **Cross-platform Ready**: Foundation for visionOS and macOS versions

## Migration Strategy

### Phased Approach
1. **Foundation Setup** - Project structure, core models, dependency injection
2. **Data Layer Migration** - Network, storage, and service implementations
3. **Core Features** - Watchlist, price streaming, alerts
4. **Advanced Features** - Charts, search, settings
5. **Polish & Optimization** - UI refinements, testing, performance

### Feature Parity & iOS 18 Enhancements
- ✅ Real-time price streaming with Live Activities
- ✅ Watchlist management with drag & drop + haptic feedback
- ✅ Price alerts with interactive notifications
- ✅ Interactive charts with Swift Charts 6.0
- ✅ Multi-language support with String Catalogs
- ✅ Interactive Widgets with App Intents
- ✅ Control Center integration for quick price checks
- ✅ Shortcuts and Siri integration
- ✅ Lock Screen and Dynamic Island support
- ✅ Offline support with enhanced caching
- ✅ Focus Modes integration
- ✅ Adaptive layouts for all device sizes

## Project Setup

### Step 1: Initialize New Project

```bash
# Create new SwiftUI project directory
mkdir Bitpal-SwiftUI && cd Bitpal-SwiftUI
git init

# Create project structure
mkdir -p Bitpal/{App,Core,Features,Resources,Preview}
mkdir -p Bitpal/App/{Launch,Navigation,Configuration}
mkdir -p Bitpal/Core/{Models,Network,Storage,Services,Extensions,Utils}
mkdir -p Bitpal/Features/{Watchlist,Alerts,Settings,CurrencyDetail,Search}
mkdir -p Bitpal/Resources/{Fonts,Localizable,Assets.xcassets}
mkdir -p BitpalWidget/{Views,Models,Resources}
mkdir -p BitpalTests/{Unit,Integration,UI}
```

### Step 2: Configure Dependencies

```swift
// Package.swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BitpalPackages",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "BitpalPackages", targets: ["BitpalPackages"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "BitpalPackages",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                "KeychainAccess"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
```

### Step 3: Project Structure

```
Bitpal-SwiftUI/
├── Bitpal/
│   ├── App/
│   │   ├── BitpalApp.swift              # App entry point with iOS 18 features
│   │   ├── AppDelegate.swift            # UIApplicationDelegate
│   │   ├── Launch/
│   │   │   ├── LaunchScreen.swift       
│   │   │   └── OnboardingView.swift     
│   │   ├── Navigation/
│   │   │   ├── NavigationManager.swift  # NavigationStack + NavigationPath
│   │   │   ├── Route.swift              
│   │   │   └── TabBarView.swift        
│   │   ├── Configuration/
│   │   │   ├── Environment.swift        
│   │   │   ├── AppConfig.swift          
│   │   │   └── Theme.swift              
│   │   └── Intents/
│   │       ├── AppIntents.swift         # App Intents for Siri/Shortcuts
│   │       ├── ControlCenterIntent.swift
│   │       └── WidgetIntents.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── SwiftData/               # SwiftData models
│   │   │   └── Observable/              # @Observable classes
│   │   ├── Network/
│   │   ├── Storage/
│   │   ├── Services/
│   │   ├── Extensions/
│   │   └── Utils/
│   ├── Features/
│   │   ├── Watchlist/
│   │   ├── Alerts/
│   │   ├── CurrencyDetail/
│   │   ├── Settings/
│   │   └── LiveActivities/             # Lock Screen + Dynamic Island
│   └── Resources/
│       ├── String Catalogs/            # iOS 18 localization
│       └── Assets.xcassets/
├── BitpalWidget/                       # Interactive Widgets
│   ├── Views/
│   ├── Intents/
│   └── LiveActivity/
├── BitpalControlCenter/                # Control Center extension
│   ├── Controls/
│   └── Configuration/
└── BitpalTests/
```

## Architecture Design

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                       │
│              SwiftUI Views & ViewModels                   │
├─────────────────────────────────────────────────────────┤
│                    Domain Layer                           │
│              Use Cases & Business Logic                   │
├─────────────────────────────────────────────────────────┤
│                     Data Layer                            │
│            Repositories & Data Sources                    │
└─────────────────────────────────────────────────────────┘
```

### Key Design Patterns
- **MVVM with @Observable**: Swift 6 observation replacing ObservableObject
- **Repository Pattern**: Abstract data access with strict concurrency
- **Dependency Injection**: Environment values and @Environment
- **SwiftData**: Modern data persistence with @Model
- **NavigationStack**: iOS 16+ navigation with type-safe routing
- **App Intents**: Siri shortcuts and automation integration
- **Swift 6 Concurrency**: Complete data race safety with Sendable types

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

#### App Entry Point

```swift
// Bitpal/App/BitpalApp.swift
import SwiftUI
import SwiftData
import Firebase
import WidgetKit
import UserNotifications

@main
struct BitpalApp: App {
    @State private var navigationManager = NavigationManager()
    @State private var authService = AuthenticationService()
    @State private var priceStreamService = PriceStreamService()
    @State private var notificationService = NotificationService()
    
    init() {
        // Configure Firebase before any other setup
        FirebaseApp.configure()
        setupAppearance()
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationManager)
                .environment(authService)
                .environment(priceStreamService)
                .environment(notificationService)
                .modelContainer(SwiftDataContainer.shared.container)
                .onAppear {
                    Task {
                        await initializeServices()
                    }
                }
                .task {
                    // Refresh widgets when app becomes active
                    WidgetCenter.shared.reloadAllTimelines()
                }
                // Handle app lifecycle events natively in SwiftUI
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await handleAppBecameActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    Task {
                        await handleAppWillResignActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    Task {
                        await handleAppDidEnterBackground()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await handleAppWillEnterForeground()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    Task {
                        await handleAppWillTerminate()
                    }
                }
                // Handle push notifications natively
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PushNotificationReceived"))) { notification in
                    Task {
                        await handlePushNotification(notification)
                    }
                }
        }
        .backgroundTask(.appRefresh("price-update")) {
            await priceStreamService.backgroundRefresh()
        }
        // Handle URL schemes and deep links
        .onOpenURL { url in
            Task {
                await handleDeepLink(url)
            }
        }
        // Handle handoff and user activities
        .onContinueUserActivity("com.bitpal.price-check") { userActivity in
            handleUserActivity(userActivity)
        }
    }
    
    private func setupAppearance() {
        // Configure iOS 18 appearance with refined styling
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupDependencies() {
        AppIntentsDependencyManager.shared.setDependencies(
            authService: authService,
            priceService: priceStreamService,
            notificationService: notificationService
        )
    }
    
    // MARK: - Service Initialization
    
    private func initializeServices() async {
        // Initialize services in proper order
        await authService.initialize()
        await notificationService.requestPermissions()
        await priceStreamService.startLiveActivity()
        
        // Register for remote notifications
        await registerForRemoteNotifications()
    }
    
    private func registerForRemoteNotifications() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }
            
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Failed to register for remote notifications: \(error)")
        }
    }
    
    // MARK: - App Lifecycle Handlers
    
    private func handleAppBecameActive() async {
        await priceStreamService.resumeStreaming()
        WidgetCenter.shared.reloadAllTimelines()
        await notificationService.updateBadgeCount()
    }
    
    private func handleAppWillResignActive() async {
        await priceStreamService.pauseStreaming()
        await authService.saveCurrentState()
    }
    
    private func handleAppDidEnterBackground() async {
        await priceStreamService.enterBackgroundMode()
        await scheduleBackgroundRefresh()
    }
    
    private func handleAppWillEnterForeground() async {
        await priceStreamService.exitBackgroundMode()
        await authService.refreshTokenIfNeeded()
    }
    
    private func handleAppWillTerminate() async {
        await priceStreamService.cleanup()
        await authService.cleanup()
    }
    
    private func scheduleBackgroundRefresh() async {
        let request = BGAppRefreshTaskRequest(identifier: "price-update")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handlePushNotification(_ notification: Notification) async {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        
        // Handle deep link from push notification
        if let deeplink = userInfo["deeplink"] as? String,
           let url = URL(string: deeplink) {
            await handleDeepLink(url)
        }
        
        // Handle alert-specific notifications
        if let alertId = userInfo["alert_id"] as? String {
            await notificationService.handleAlertNotification(alertId: alertId)
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        switch components.host {
        case "currency":
            if let symbol = components.queryItems?.first(where: { $0.name == "symbol" })?.value {
                await navigationManager.navigateToCurrency(symbol: symbol)
            }
        case "alert":
            if let alertId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                await navigationManager.navigateToAlert(id: alertId)
            }
        case "watchlist":
            await navigationManager.navigateToWatchlist()
        default:
            break
        }
    }
    
    private func handleUserActivity(_ userActivity: NSUserActivity) {
        // Handle handoff and Siri shortcuts
        if let currencySymbol = userActivity.userInfo?["currency"] as? String {
            Task {
                await navigationManager.navigateToCurrency(symbol: currencySymbol)
            }
        }
    }
}

// MARK: - Supporting Services

@MainActor
@Observable
final class NotificationService: Sendable {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var badgeCount: Int = 0
    
    func requestPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
            
            if granted {
                // Set up notification categories and actions
                await setupNotificationCategories()
            }
        } catch {
            print("Failed to request notification permissions: \(error)")
        }
    }
    
    private func setupNotificationCategories() async {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ALERT",
            title: "View",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ALERT",
            title: "Dismiss",
            options: []
        )
        
        let alertCategory = UNNotificationCategory(
            identifier: "PRICE_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        await UNUserNotificationCenter.current().setNotificationCategories([alertCategory])
    }
    
    func updateBadgeCount() async {
        // Update app badge with unread alert count
        let alertCount = await AlertService.shared.getUnreadAlertCount()
        badgeCount = alertCount
        
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = alertCount
        }
    }
    
    func handleAlertNotification(alertId: String) async {
        // Handle alert-specific notification logic
        await AlertService.shared.markAlertAsRead(alertId: alertId)
        await updateBadgeCount()
    }
}

// Enhanced dependency manager for future-proofing
@MainActor
final class AppIntentsDependencyManager: Sendable {
    static let shared = AppIntentsDependencyManager()
    
    private var _authService: AuthenticationService?
    private var _priceService: PriceStreamService?
    private var _notificationService: NotificationService?
    
    private init() {}
    
    func setDependencies(
        authService: AuthenticationService,
        priceService: PriceStreamService,
        notificationService: NotificationService
    ) {
        _authService = authService
        _priceService = priceService
        _notificationService = notificationService
    }
    
    var authService: AuthenticationService? { _authService }
    var priceService: PriceStreamService? { _priceService }
    var notificationService: NotificationService? { _notificationService }
}
```

## AppDelegate Deprecation Preparation

### Future-Proofing Strategy

The above implementation eliminates `@UIApplicationDelegateAdaptor` and handles all app lifecycle events natively within SwiftUI's `App` protocol. This prepares the codebase for iOS 26 when AppDelegate may be deprecated.

### Key Changes for AppDelegate-Free Architecture

**1. Native SwiftUI Lifecycle Management:**
```swift
// Instead of AppDelegate methods, use SwiftUI modifiers:
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification))
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification))
```

**2. Push Notification Handling:**
```swift
// Native SwiftUI approach without AppDelegate
private func registerForRemoteNotifications() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    guard settings.authorizationStatus == .authorized else { return }
    
    await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

**3. Deep Link Management:**
```swift
// SwiftUI native deep link handling
.onOpenURL { url in
    Task { await handleDeepLink(url) }
}
.onContinueUserActivity("com.bitpal.price-check") { userActivity in
    handleUserActivity(userActivity)
}
```

**4. Background Task Scheduling:**
```swift
// Modern background task management
.backgroundTask(.appRefresh("price-update")) {
    await priceStreamService.backgroundRefresh()
}
```

### Benefits of AppDelegate-Free Architecture

- **Future-Proof**: Ready for iOS 26+ when AppDelegate may be deprecated
- **SwiftUI Native**: All lifecycle management happens within SwiftUI
- **Better Testing**: Easier to unit test individual lifecycle handlers
- **Cleaner Code**: No UIKit bridging required
- **Modern Patterns**: Uses latest iOS patterns and APIs
- **Performance**: Reduced overhead from UIKit bridging

### Migration Path from Current UIKit Apps

For teams migrating from AppDelegate-based apps:

1. **Move Firebase configuration** to App initializer
2. **Replace AppDelegate methods** with SwiftUI notification publishers
3. **Handle push notifications** through UserNotifications framework directly
4. **Use native SwiftUI** for deep links and user activities
5. **Migrate background tasks** to SwiftUI background task modifiers

This approach ensures the app will continue working seamlessly even when Apple eventually deprecates AppDelegate in future iOS versions.

## Additional iOS 26 Future-Proofing Strategies

### 1. Eliminate Remaining UIKit Dependencies

**Current Risk**: Apple may further deprecate UIKit components in favor of SwiftUI-native alternatives.

**Preparation Strategy**:
```swift
// Instead of UIKit appearance proxies, use SwiftUI styling
// AVOID: UIKit appearance customization
UINavigationBar.appearance().standardAppearance = appearance

// PREFER: SwiftUI native styling
.navigationBarTitleDisplayMode(.large)
.toolbarBackground(.visible, for: .navigationBar)
.toolbarColorScheme(.dark, for: .navigationBar)
```

**Implementation**:
```swift
// Replace UIKit-based styling with SwiftUI equivalents
struct AppTheme {
    static func apply() {
        // Pure SwiftUI theming - no UIKit dependencies
    }
}

// Custom navigation styling
extension View {
    func bitpalNavigationStyle() -> some View {
        self
            .navigationBarTitleDisplayMode(.automatic)
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbarBackground(.regularMaterial, for: .tabBar)
    }
}
```

### 2. Prepare for Potential UIApplication API Changes

**Current Risk**: `UIApplication.shared` may become more restricted or deprecated.

**Preparation Strategy**:
```swift
// Create abstraction layer for system interactions
@MainActor
protocol SystemInteractionService: Sendable {
    func openURL(_ url: URL) async -> Bool
    func registerForRemoteNotifications() async
    func setBadgeNumber(_ number: Int) async
    func requestReview() async
}

@MainActor
final class ModernSystemService: SystemInteractionService {
    func openURL(_ url: URL) async -> Bool {
        // Future-proof URL opening
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume(returning: UIApplication.shared.canOpenURL(url))
            }
        }
    }
    
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func setBadgeNumber(_ number: Int) async {
        // Prepare for potential badge API changes
        await MainActor.run {
            UNUserNotificationCenter.current().setBadgeCount(number)
        }
    }
    
    func requestReview() async {
        // Use StoreKit instead of UIApplication
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            await SKStoreReviewController.requestReview(in: scene)
        }
    }
}
```

### 3. Enhanced Privacy and Security Preparation

**Expected iOS 26 Changes**: Stricter privacy controls and data handling requirements.

**Preparation Strategy**:
```swift
// Privacy-first architecture
@MainActor
@Observable
final class PrivacyManager: Sendable {
    private(set) var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    func requestTrackingPermission() async {
        trackingAuthorizationStatus = await ATTrackingManager.requestTrackingAuthorization()
    }
    
    // Prepare for more granular privacy controls
    func requestDataProcessingConsent() async -> Bool {
        // Future API for explicit data processing consent
        return true
    }
    
    func minimizeDataCollection() {
        // Implement privacy-by-design patterns
        // Only collect essential data for app functionality
    }
}

// Enhanced data encryption for local storage
struct SecureStorageManager {
    static func store<T: Codable>(_ object: T, key: String) throws {
        let data = try JSONEncoder().encode(object)
        let encryptedData = try CryptoKit.AES.GCM.seal(data, using: getOrCreateKey())
        UserDefaults.standard.set(encryptedData.combined, forKey: key)
    }
    
    private static func getOrCreateKey() -> SymmetricKey {
        // Use Secure Enclave when possible
        return SymmetricKey(size: .bits256)
    }
}
```

### 4. Prepare for Potential Core Data Deprecation

**Current Risk**: Apple may push SwiftData as the exclusive persistence solution.

**Preparation Strategy** (Already implemented with SwiftData):
```swift
// Ensure complete SwiftData adoption
@Model
final class CurrencyPair: Sendable {
    // Full SwiftData implementation - no Core Data dependencies
}

// Migration utility for future data format changes
struct DataMigrationManager {
    static func migrateToLatestFormat() async throws {
        // Prepare for potential SwiftData format changes
        let container = SwiftDataContainer.shared.container
        try await container.mainContext.save()
    }
}
```

### 5. Enhanced Accessibility Preparation

**Expected iOS 26 Changes**: More sophisticated accessibility requirements and AI-powered features.

**Preparation Strategy**:
```swift
// Enhanced accessibility implementation
extension View {
    func enhancedAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            // Prepare for AI-powered accessibility descriptions
            .accessibilityElement(children: .combine)
    }
}

// Voice Control preparation
struct VoiceControlCommands {
    static func registerCommands() {
        // Prepare for enhanced voice control in iOS 26
    }
}
```

### 6. Prepare for Enhanced AI Integration

**Expected iOS 26 Changes**: Deeper AI integration throughout the system.

**Preparation Strategy**:
```swift
// AI-ready architecture
@MainActor
@Observable
final class AIInsightsService: Sendable {
    func generatePriceInsights(for pairs: [CurrencyPair]) async -> [String] {
        // Prepare for Core ML integration
        // Future: On-device price prediction and insights
        return []
    }
    
    func generateSmartAlerts(based on: [HistoricalPrice]) async -> [Alert] {
        // Prepare for AI-suggested price alerts
        return []
    }
    
    // Prepare for Siri AI integration
    func enhanceSiriResponses() async {
        // Future: More natural Siri interactions
    }
}

// Prepare for Vision Pro integration
#if os(visionOS)
extension ContentView {
    var visionProLayout: some View {
        // Spatial computing ready
        NavigationSplitView {
            // Sidebar
        } detail: {
            // Detail view optimized for Vision Pro
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            // Floating controls for Vision Pro
        }
    }
}
#endif
```

### 7. Enhanced Cross-Platform Preparation

**Expected iOS 26 Changes**: Better cross-platform development tools and shared code.

**Preparation Strategy**:
```swift
// Shared business logic across platforms
public final class BitpalCore: Sendable {
    // Platform-agnostic business logic
    public static func calculatePriceChange(current: Double, previous: Double) -> Double {
        return ((current - previous) / previous) * 100
    }
    
    public static func formatCurrency(_ amount: Double, code: String) -> String {
        // Platform-neutral formatting
        return amount.formatted(.currency(code: code))
    }
}

// Platform-specific implementations
#if os(iOS)
typealias PlatformSpecificView = iOSSpecificView
#elseif os(macOS)
typealias PlatformSpecificView = macOSSpecificView
#elseif os(visionOS)
typealias PlatformSpecificView = visionOSSpecificView
#endif
```

### 8. Prepare for Enhanced Security Requirements

**Expected iOS 26 Changes**: Stricter app security and code signing requirements.

**Preparation Strategy**:
```swift
// Enhanced security measures
struct SecurityManager {
    static func validateAppIntegrity() async -> Bool {
        // Prepare for enhanced app integrity checks
        return true
    }
    
    static func enableEnhancedEncryption() {
        // Use latest encryption standards
        // Prepare for quantum-resistant encryption
    }
    
    // Prepare for biometric enhancements
    static func authenticateWithAdvancedBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access crypto data"
            )
        } catch {
            return false
        }
    }
}
```

### 9. Performance and Energy Efficiency Preparation

**Expected iOS 26 Changes**: Stricter performance and energy usage monitoring.

**Preparation Strategy**:
```swift
// Enhanced performance monitoring
@MainActor
@Observable
final class PerformanceMonitor: Sendable {
    private(set) var cpuUsage: Double = 0
    private(set) var memoryUsage: Double = 0
    private(set) var energyImpact: String = "Low"
    
    func startMonitoring() {
        // Use MetricKit for performance monitoring
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.updateMetrics()
            }
        }
    }
    
    private func updateMetrics() async {
        // Implement efficient performance tracking
        // Prepare for iOS 26 energy efficiency requirements
    }
}

// Optimized networking for energy efficiency
actor EfficientNetworkManager {
    func batchRequests() async {
        // Batch network requests to reduce energy impact
        // Prepare for stricter energy usage policies
    }
}
```

### 10. Updated Development Timeline

**Enhanced Phase 1: Foundation & Future-Proofing (Weeks 1-4)**
- Swift 6 project initialization with strict concurrency
- AppDelegate-free SwiftUI App architecture
- SwiftData model implementation
- Enhanced privacy and security setup
- Cross-platform architecture foundation
- AI-ready service abstractions
- Performance monitoring setup
```

#### Core Models with SwiftData

```swift
// Bitpal/Core/Models/SwiftData/CurrencyPair.swift
import Foundation
import SwiftData

@Model
final class CurrencyPair: Sendable {
    @Attribute(.unique) var id: UUID
    var baseCurrency: String
    var quoteCurrency: String
    var exchange: String
    var currentPrice: Double
    var priceChange24h: Double
    var priceChangePercent24h: Double
    var volume24h: Double
    var high24h: Double
    var low24h: Double
    var lastUpdated: Date
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade) var alerts: [Alert] = []
    @Relationship(deleteRule: .cascade) var priceHistory: [HistoricalPrice] = []
    
    init(id: UUID = UUID(), baseCurrency: String, quoteCurrency: String, exchange: String) {
        self.id = id
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self.exchange = exchange
        self.currentPrice = 0
        self.priceChange24h = 0
        self.priceChangePercent24h = 0
        self.volume24h = 0
        self.high24h = 0
        self.low24h = 0
        self.lastUpdated = Date()
        self.sortOrder = 0
    }
    
    var displayName: String {
        "\(baseCurrency)/\(quoteCurrency)"
    }
    
    var isPositiveChange: Bool {
        priceChange24h >= 0
    }
    
    // For Live Activities and widgets
    var widgetDisplayData: WidgetCurrencyData {
        WidgetCurrencyData(
            symbol: displayName,
            price: currentPrice,
            change: priceChangePercent24h,
            lastUpdated: lastUpdated
        )
    }
}

// Bitpal/Core/Models/Observable/StreamPrice.swift
import Foundation

struct StreamPrice: Codable, Sendable {
    let type: String
    let exchange: String
    let baseCurrency: String
    let quoteCurrency: String
    let price: Double
    let volume24h: Double?
    let high24Hour: Double?
    let low24Hour: Double?
    let open24Hour: Double?
    
    private enum CodingKeys: String, CodingKey {
        case type = "TYPE"
        case exchange = "MARKET"
        case baseCurrency = "FROMSYMBOL"
        case quoteCurrency = "TOSYMBOL"
        case price = "PRICE"
        case volume24h = "VOLUME24HOUR"
        case high24Hour = "HIGH24HOUR"
        case low24Hour = "LOW24HOUR"
        case open24Hour = "OPEN24HOUR"
    }
}

// Bitpal/Core/Models/SwiftData/Alert.swift
@Model
final class Alert: Sendable {
    @Attribute(.unique) var id: UUID
    var comparison: AlertComparison
    var targetPrice: Double
    var isEnabled: Bool
    var createdAt: Date
    var lastTriggered: Date?
    
    @Relationship(inverse: \CurrencyPair.alerts) var currencyPair: CurrencyPair?
    
    init(id: UUID = UUID(), comparison: AlertComparison, targetPrice: Double, isEnabled: Bool = true) {
        self.id = id
        self.comparison = comparison
        self.targetPrice = targetPrice
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}

enum AlertComparison: String, CaseIterable, Codable, Sendable {
    case above = "above"
    case below = "below"
    
    var symbol: String {
        switch self {
        case .above: return "≥"
        case .below: return "≤"
        }
    }
}

// Shared widget data structure
struct WidgetCurrencyData: Codable, Sendable {
    let symbol: String
    let price: Double
    let change: Double
    let lastUpdated: Date
}
```

### Phase 2: Data Layer (Week 3-4)

#### Network Layer

```swift
// Bitpal/Core/Network/APIClient.swift
import Foundation
import Combine

actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let baseURL: URL
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
        self.baseURL = URL(string: AppConfig.apiBaseURL)!
        
        decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let url = endpoint.url(baseURL: baseURL)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try decoder.decode(T.self, from: data)
    }
}
```

#### WebSocket Manager

```swift
// Bitpal/Core/Network/WebSocketManager.swift
import Foundation
import Combine

@MainActor
class WebSocketManager: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var lastError: Error?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private let session = URLSession.shared
    private var subscriptions = Set<String>()
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }
    
    func connect() async {
        guard connectionState == .disconnected else { return }
        
        connectionState = .connecting
        
        let url = URL(string: "\(AppConfig.socketBaseURL)?api_key=\(AppConfig.apiKey)")!
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        connectionState = .connected
        startPingTimer()
        
        // Re-subscribe to previous subscriptions
        for subscription in subscriptions {
            await subscribe(to: subscription)
        }
        
        // Start receiving messages
        await receiveMessage()
    }
    
    func subscribe(to symbol: String) async {
        subscriptions.insert(symbol)
        
        guard connectionState == .connected else { return }
        
        let message = URLSessionWebSocketTask.Message.string(
            """
            {"action": "SubAdd", "subs": ["\(symbol)"]}
            """
        )
        
        do {
            try await webSocketTask?.send(message)
        } catch {
            lastError = error
            await handleConnectionError()
        }
    }
    
    private func receiveMessage() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let message = try await webSocketTask.receive()
            
            switch message {
            case .string(let text):
                await handleMessage(text)
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    await handleMessage(text)
                }
            @unknown default:
                break
            }
            
            // Continue receiving messages
            await receiveMessage()
            
        } catch {
            lastError = error
            await handleConnectionError()
        }
    }
    
    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let streamPrice = try JSONDecoder().decode(StreamPrice.self, from: data)
            await PriceStreamService.shared.updatePrice(streamPrice)
        } catch {
            print("Failed to parse WebSocket message: \(error)")
        }
    }
}
```

### Phase 3: Core Features (Week 5-8)

#### Watchlist Implementation

```swift
// Bitpal/Features/Watchlist/Views/WatchlistView.swift
import SwiftUI
import CoreData

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CurrencyPair.sortOrder, ascending: true)],
        animation: .default
    ) private var currencyPairs: FetchedResults<CurrencyPair>
    
    @State private var showingAddCurrency = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if currencyPairs.isEmpty {
                    EmptyStateView(
                        title: "No Currencies",
                        message: "Add cryptocurrencies to start tracking prices",
                        actionTitle: "Add Currency",
                        action: { showingAddCurrency = true }
                    )
                } else {
                    currencyList
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCurrency = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCurrency) {
                AddCurrencyView()
            }
            .task {
                await viewModel.startPriceStreaming(for: Array(currencyPairs))
            }
            .refreshable {
                await viewModel.refreshPrices()
            }
        }
    }
    
    private var currencyList: some View {
        List {
            ForEach(currencyPairs) { pair in
                NavigationLink(destination: CurrencyDetailView(currencyPair: pair)) {
                    WatchlistRow(currencyPair: pair)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deletePair(pair)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: movePairs)
            .onDelete(perform: deletePairs)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
    
    private func movePairs(from source: IndexSet, to destination: Int) {
        var pairs = Array(currencyPairs)
        pairs.move(fromOffsets: source, toOffset: destination)
        
        for (index, pair) in pairs.enumerated() {
            pair.sortOrder = Int32(index)
        }
        
        try? viewContext.save()
    }
    
    private func deletePairs(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deletePair(currencyPairs[index])
        }
    }
}

// Bitpal/Features/Watchlist/Views/WatchlistRow.swift
struct WatchlistRow: View {
    @ObservedObject var currencyPair: CurrencyPair
    @EnvironmentObject private var priceStreamService: PriceStreamService
    @State private var animatePrice = false
    
    private var streamPrice: StreamPrice? {
        let key = "\(currencyPair.baseCurrency)-\(currencyPair.quoteCurrency)-\(currencyPair.exchange)"
        return priceStreamService.prices[key]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency Icon
            CurrencyIcon(symbol: currencyPair.baseCurrency)
                .frame(width: 40, height: 40)
            
            // Currency Info
            VStack(alignment: .leading, spacing: 4) {
                Text(currencyPair.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(currencyPair.exchange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatPrice(streamPrice?.price ?? currencyPair.currentPrice))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .scaleEffect(animatePrice ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animatePrice)
                
                PriceChangeView(
                    change: currencyPair.priceChange24h,
                    changePercent: currencyPair.priceChangePercent24h
                )
            }
        }
        .padding(.vertical, 4)
        .onChange(of: streamPrice?.price) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation {
                    animatePrice = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animatePrice = false
                }
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price > 1000 {
            return String(format: "$%.0f", price)
        } else if price > 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
}
```

#### Currency Detail with Charts

```swift
// Bitpal/Features/CurrencyDetail/Views/CurrencyDetailView.swift
import SwiftUI
import Charts

struct CurrencyDetailView: View {
    @ObservedObject var currencyPair: CurrencyPair
    @StateObject private var viewModel: CurrencyDetailViewModel
    @State private var selectedPeriod: ChartPeriod = .day
    @State private var showingCreateAlert = false
    
    init(currencyPair: CurrencyPair) {
        self.currencyPair = currencyPair
        self._viewModel = StateObject(wrappedValue: CurrencyDetailViewModel(currencyPair: currencyPair))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Price Header
                priceHeader
                
                // Chart Period Selector
                ChartPeriodPicker(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal)
                
                // Price Chart
                if viewModel.isLoadingChart {
                    ProgressView()
                        .frame(height: 300)
                } else {
                    PriceChartView(
                        data: viewModel.chartData,
                        period: selectedPeriod
                    )
                    .frame(height: 300)
                    .padding(.horizontal)
                }
                
                // Statistics
                StatisticsView(currencyPair: currencyPair)
                    .padding(.horizontal)
                
                // Create Alert Button
                Button {
                    showingCreateAlert = true
                } label: {
                    Label("Create Price Alert", systemImage: "bell.badge")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(currencyPair.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateAlert) {
            CreateAlertView(currencyPair: currencyPair)
        }
        .task {
            await viewModel.loadChartData(for: selectedPeriod)
        }
        .onChange(of: selectedPeriod) { _, newPeriod in
            Task {
                await viewModel.loadChartData(for: newPeriod)
            }
        }
    }
    
    private var priceHeader: some View {
        VStack(spacing: 8) {
            Text(formatPrice(currencyPair.currentPrice))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                PriceChangeView(
                    change: currencyPair.priceChange24h,
                    changePercent: currencyPair.priceChangePercent24h
                )
                .font(.title3)
                
                Text("24h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// Bitpal/Features/CurrencyDetail/Views/PriceChartView.swift
struct PriceChartView: View {
    let data: [ChartData]
    let period: ChartPeriod
    
    @State private var selectedPrice: ChartData?
    @State private var chartType: ChartType = .line
    
    enum ChartType: String, CaseIterable {
        case line = "Line"
        case candle = "Candle"
        
        var icon: String {
            switch self {
            case .line: return "chart.line.uptrend.xyaxis"
            case .candle: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Type Picker
            HStack {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            chartType = type
                        }
                    } label: {
                        Image(systemName: type.icon)
                            .font(.title2)
                            .foregroundColor(chartType == type ? .accentColor : .secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedPrice {
                    VStack(alignment: .trailing) {
                        Text(formatPrice(selected.close))
                            .font(.headline)
                        Text(formatDate(selected.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Chart
            if chartType == .line {
                lineChart
            } else {
                candleChart
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var lineChart: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Time", item.date),
                y: .value("Price", item.close)
            )
            .foregroundStyle(Color.accentColor)
            .interpolationMethod(.catmullRom)
            
            if let selected = selectedPrice, selected.id == item.id {
                RuleMark(x: .value("Time", selected.date))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                PointMark(
                    x: .value("Time", selected.date),
                    y: .value("Price", selected.close)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(100)
            }
            
            AreaMark(
                x: .value("Time", item.date),
                y: .value("Price", item.close)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: period.xAxisStride)) { value in
                AxisGridLine()
                AxisValueLabel(format: period.xAxisFormat)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(location: location, geometry: geometry, proxy: proxy)
                    }
            }
        }
    }
}
```

### Phase 4: iOS 18 Services Implementation

#### Price Stream Service with Live Activities

```swift
// Bitpal/Core/Services/PriceStreamService.swift
import Foundation
import Combine
import SwiftData
import ActivityKit
import WidgetKit

@MainActor
@Observable
final class PriceStreamService: Sendable {
    static let shared = PriceStreamService()
    
    private(set) var prices: [String: StreamPrice] = [:]
    private(set) var isStreaming = false
    private(set) var currentActivity: Activity<PriceLiveActivityAttributes>?
    
    private let webSocketManager = WebSocketManager()
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        webSocketManager.$connectionState
            .map { $0 == .connected }
            .sink { [weak self] isConnected in
                self?.isStreaming = isConnected
            }
            .store(in: &cancellables)
    }
    
    func startStreaming(for pairs: [CurrencyPair]) async {
        await webSocketManager.connect()
        
        for pair in pairs {
            let subscription = "5~\(pair.exchange)~\(pair.baseCurrency)~\(pair.quoteCurrency)"
            await webSocketManager.subscribe(to: subscription)
        }
    }
    
    func startLiveActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = PriceLiveActivityAttributes()
        let initialState = PriceLiveActivityAttributes.ContentState(
            prices: [],
            lastUpdated: Date()
        )
        
        do {
            currentActivity = try Activity<PriceLiveActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: .token
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updatePrice(_ streamPrice: StreamPrice) async {
        let key = "\(streamPrice.baseCurrency)-\(streamPrice.quoteCurrency)-\(streamPrice.exchange)"
        prices[key] = streamPrice
        
        // Update SwiftData
        await updateSwiftDataPrice(streamPrice)
        
        // Update Live Activity
        await updateLiveActivity()
        
        // Update Widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateSwiftDataPrice(_ streamPrice: StreamPrice) async {
        let modelContext = SwiftDataContainer.shared.container.mainContext
        
        let descriptor = FetchDescriptor<CurrencyPair>(
            predicate: #Predicate { pair in
                pair.baseCurrency == streamPrice.baseCurrency &&
                pair.quoteCurrency == streamPrice.quoteCurrency &&
                pair.exchange == streamPrice.exchange
            }
        )
        
        do {
            let pairs = try modelContext.fetch(descriptor)
            if let pair = pairs.first {
                pair.currentPrice = streamPrice.price
                if let open24h = streamPrice.open24Hour {
                    pair.priceChange24h = streamPrice.price - open24h
                    pair.priceChangePercent24h = ((streamPrice.price - open24h) / open24h) * 100
                }
                pair.volume24h = streamPrice.volume24h ?? 0
                pair.high24h = streamPrice.high24Hour ?? 0
                pair.low24h = streamPrice.low24Hour ?? 0
                pair.lastUpdated = Date()
                
                try modelContext.save()
            }
        } catch {
            print("Failed to update price in SwiftData: \(error)")
        }
    }
    
    private func updateLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        let updatedState = PriceLiveActivityAttributes.ContentState(
            prices: Array(prices.values.prefix(3)).map { streamPrice in
                WidgetCurrencyData(
                    symbol: "\(streamPrice.baseCurrency)/\(streamPrice.quoteCurrency)",
                    price: streamPrice.price,
                    change: ((streamPrice.price - (streamPrice.open24Hour ?? streamPrice.price)) / (streamPrice.open24Hour ?? streamPrice.price)) * 100,
                    lastUpdated: Date()
                )
            },
            lastUpdated: Date()
        )
        
        await activity.update(
            ActivityContent(state: updatedState, staleDate: Date().addingTimeInterval(300))
        )
    }
    
    func backgroundRefresh() async {
        // Background app refresh for price updates
        await fetchLatestPrices()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func fetchLatestPrices() async {
        // Implementation for background price fetching
    }
}

// Live Activity Attributes
struct PriceLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let prices: [WidgetCurrencyData]
        let lastUpdated: Date
    }
}
```

#### Alert Service

```swift
// Bitpal/Core/Services/AlertService.swift
import Foundation
import CoreData
import UserNotifications

@MainActor
class AlertService: ObservableObject {
    static let shared = AlertService()
    
    @Published private(set) var alerts: [Alert] = []
    @Published private(set) var isLoading = false
    
    private let apiClient = APIClient.shared
    private let viewContext = PersistenceController.shared.container.viewContext
    private var priceObserver: AnyCancellable?
    
    private init() {
        setupPriceObserver()
        Task {
            await loadAlerts()
        }
    }
    
    private func setupPriceObserver() {
        priceObserver = PriceStreamService.shared.$prices
            .sink { [weak self] prices in
                Task {
                    await self?.checkAlerts(with: prices)
                }
            }
    }
    
    func createAlert(for pair: CurrencyPair,
                     comparison: Alert.ComparisonOperator,
                     targetPrice: Double) async throws {
        let alert = Alert(context: viewContext)
        alert.id = UUID()
        alert.currencyPairId = pair.id
        alert.currencyPair = pair
        alert.comparisonOperator = comparison
        alert.targetPrice = targetPrice
        alert.isEnabled = true
        alert.createdAt = Date()
        
        try viewContext.save()
        await loadAlerts()
        
        // Sync with backend
        let request = CreateAlertRequest(
            pair: pair.displayName,
            exchange: pair.exchange,
            comparison: comparison.rawValue,
            reference: targetPrice,
            isEnabled: true
        )
        
        let _: CreateAlertResponse = try await apiClient.request(.createAlert(request))
    }
    
    private func checkAlerts(with prices: [String: StreamPrice]) async {
        let enabledAlerts = alerts.filter { $0.isEnabled }
        
        for alert in enabledAlerts {
            guard let pair = alert.currencyPair else { continue }
            
            let key = "\(pair.baseCurrency)-\(pair.quoteCurrency)-\(pair.exchange)"
            guard let streamPrice = prices[key] else { continue }
            
            let shouldTrigger: Bool
            switch alert.comparisonOperator {
            case .above:
                shouldTrigger = streamPrice.price >= alert.targetPrice
            case .below:
                shouldTrigger = streamPrice.price <= alert.targetPrice
            }
            
            if shouldTrigger && (alert.lastTriggered == nil || 
                Date().timeIntervalSince(alert.lastTriggered!) > 3600) {
                await triggerAlert(alert, currentPrice: streamPrice.price)
            }
        }
    }
    
    private func triggerAlert(_ alert: Alert, currentPrice: Double) async {
        alert.lastTriggered = Date()
        try? viewContext.save()
        
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "Price Alert"
        content.body = "\(alert.currencyPair?.displayName ?? "") is now \(alert.comparisonOperator.rawValue) your target price of \(alert.targetPrice)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

## Testing Strategy

### Unit Testing

```swift
// BitpalTests/Unit/ViewModels/WatchlistViewModelTests.swift
import XCTest
@testable import Bitpal

@MainActor
class WatchlistViewModelTests: XCTestCase {
    var viewModel: WatchlistViewModel!
    var mockContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        mockContext = PersistenceController(inMemory: true).container.viewContext
        viewModel = WatchlistViewModel()
    }
    
    func testDeletePair() throws {
        // Given
        let pair = CurrencyPair(context: mockContext)
        pair.baseCurrency = "BTC"
        pair.quoteCurrency = "USD"
        try mockContext.save()
        
        // When
        viewModel.deletePair(pair)
        
        // Then
        let request: NSFetchRequest<CurrencyPair> = CurrencyPair.fetchRequest()
        let count = try mockContext.count(for: request)
        XCTAssertEqual(count, 0)
    }
}
```

### UI Testing

```swift
// BitpalTests/UI/WatchlistUITests.swift
import XCTest

class WatchlistUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    func testAddCurrency() {
        // Tap add button
        app.navigationBars["Watchlist"].buttons["plus"].tap()
        
        // Search for Bitcoin
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Bitcoin")
        
        // Select Bitcoin
        app.tables.cells.containing(.staticText, identifier: "Bitcoin").firstMatch.tap()
        
        // Tap Add button
        app.buttons["Add 1 Currency"].tap()
        
        // Verify Bitcoin appears in watchlist
        XCTAssertTrue(app.tables.cells.containing(.staticText, identifier: "BTC/USD").element.exists)
    }
}
```

## iOS 18 Specific Features

### App Intents Implementation

```swift
// Bitpal/App/Intents/AppIntents.swift
import AppIntents
import SwiftUI

struct GetCryptoPriceIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Crypto Price"
    static let description = IntentDescription("Get the current price of a cryptocurrency")
    
    @Parameter(title: "Currency Pair")
    var currencyPair: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get price for \(\.$currencyPair)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let priceService = AppIntentsDependencyManager.shared.priceService else {
            throw IntentError.serviceUnavailable
        }
        
        let price = await priceService.getCurrentPrice(for: currencyPair)
        let formattedPrice = price.formatted(.currency(code: "USD"))
        
        return .result(
            dialog: "The current price of \(currencyPair) is \(formattedPrice)"
        )
    }
}

struct CreatePriceAlertIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Price Alert"
    static let description = IntentDescription("Create a price alert for a cryptocurrency")
    
    @Parameter(title: "Currency")
    var currency: String
    
    @Parameter(title: "Target Price")
    var targetPrice: Double
    
    @Parameter(title: "Alert When", default: AlertDirection.above)
    var direction: AlertDirection
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Implementation for creating alerts via Siri
        return .result(dialog: "Price alert created for \(currency)")
    }
}

enum AlertDirection: String, AppEnum {
    case above = "above"
    case below = "below"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Alert Direction")
    static let caseDisplayRepresentations: [AlertDirection: DisplayRepresentation] = [
        .above: "Above",
        .below: "Below"
    ]
}

// App Shortcuts Provider
struct BitpalShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetCryptoPriceIntent(),
            phrases: [
                "Get Bitcoin price in \(.applicationName)",
                "Check crypto prices in \(.applicationName)",
                "What's the price of \(\.$currencyPair) in \(.applicationName)"
            ],
            shortTitle: "Get Price",
            systemImageName: "dollarsign.circle"
        )
        
        AppShortcut(
            intent: CreatePriceAlertIntent(),
            phrases: [
                "Create price alert in \(.applicationName)",
                "Set alert for \(\.$currency) in \(.applicationName)"
            ],
            shortTitle: "Create Alert",
            systemImageName: "bell"
        )
    }
}
```

### Control Center Integration

```swift
// BitpalControlCenter/Controls/PriceControlConfiguration.swift
import ControlCenterUI
import SwiftUI

struct PriceControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Crypto Price"
    static let description = IntentDescription("Quick access to cryptocurrency prices")
    
    @Parameter(title: "Currency Pair")
    var currencyPair: String = "BTC/USD"
}

struct PriceControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.bitpal.pricecontrol",
            provider: PriceControlProvider()
        ) { value in
            ControlWidgetButton(action: OpenAppIntent()) {
                VStack(spacing: 2) {
                    Text(value.symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    Text(value.price.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("\(value.change > 0 ? "+" : "")\(value.change, specifier: "%.2f")%")
                        .font(.caption2)
                        .foregroundColor(value.change > 0 ? .green : .red)
                }
            }
        }
        .displayName("Crypto Price")
        .description("Quick view of cryptocurrency prices")
    }
}

struct PriceControlProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (PriceControlEntry) -> Void) {
        let entry = PriceControlEntry(
            date: Date(),
            symbol: "BTC/USD",
            price: 50000,
            change: 2.5
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PriceControlEntry>) -> Void) {
        // Implementation for updating Control Center widget
    }
}

struct PriceControlEntry: TimelineEntry {
    let date: Date
    let symbol: String
    let price: Double
    let change: Double
}
```

### Interactive Widgets

```swift
// BitpalWidget/Views/InteractiveWidgetView.swift
import SwiftUI
import WidgetKit
import AppIntents

struct BitpalWidget: Widget {
    let kind: String = "BitpalWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCurrencyIntent.self, provider: Provider()) { entry in
            BitpalWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Crypto Prices")
        .description("Track your favorite cryptocurrency prices")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BitpalWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.currencies.prefix(3), id: \.symbol) { currency in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currency.symbol)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(currency.price.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button(intent: RefreshPriceIntent(symbol: currency.symbol)) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(currency.change > 0 ? "+" : "")\(currency.change, specifier: "%.2f")%")
                        .font(.caption2)
                        .foregroundColor(currency.change > 0 ? .green : .red)
                }
            }
        }
        .padding()
    }
}

// Interactive widget intent
struct RefreshPriceIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Price"
    
    @Parameter(title: "Symbol")
    var symbol: String
    
    func perform() async throws -> some IntentResult {
        // Refresh specific currency price
        WidgetCenter.shared.reloadTimelines(ofKind: "BitpalWidget")
        return .result()
    }
}
```

### Live Activity Implementation

```swift
// Bitpal/Features/LiveActivities/PriceLiveActivity.swift
import ActivityKit
import SwiftUI

struct PriceLiveActivityView: View {
    let context: ActivityViewContext<PriceLiveActivityAttributes>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Crypto Prices")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(context.state.prices.prefix(2), id: \.symbol) { price in
                    HStack {
                        Text(price.symbol)
                            .font(.caption2)
                        
                        Spacer()
                        
                        Text(price.price.formatted(.currency(code: "USD")))
                            .font(.caption2)
                            .fontWeight(.semibold)
                        
                        Text("\(price.change > 0 ? "+" : "")\(price.change, specifier: "%.1f")%")
                            .font(.caption2)
                            .foregroundColor(price.change > 0 ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Text("Last Update")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(context.state.lastUpdated.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding()
    }
}

// Dynamic Island implementation
extension PriceLiveActivityView {
    var dynamicIslandCompact: some View {
        HStack {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(.orange)
            
            Text("BTC: $50,000")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
    
    var dynamicIslandExpanded: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(context.state.prices.prefix(3), id: \.symbol) { price in
                HStack {
                    Text(price.symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(price.price.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("\(price.change > 0 ? "+" : "")\(price.change, specifier: "%.2f")%")
                            .font(.caption2)
                            .foregroundColor(price.change > 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
    }
}
```

## Migration Patterns

### ObservableObject to @Observable

```swift
// OLD: ObservableObject
class PriceViewModel: ObservableObject {
    @Published var prices: [CurrencyPair] = []
    @Published var isLoading = false
}

// NEW: @Observable (iOS 17+)
@Observable
final class PriceViewModel {
    var prices: [CurrencyPair] = []
    var isLoading = false
}

// Usage in SwiftUI
struct PriceView: View {
    @State private var viewModel = PriceViewModel()
    
    var body: some View {
        List(viewModel.prices) { price in
            // View content
        }
        .task {
            await viewModel.loadPrices()
        }
    }
}
```

### Core Data to SwiftData

```swift
// OLD: Core Data
@NSManaged public var id: UUID
@NSManaged public var baseCurrency: String

// NEW: SwiftData
@Model
final class CurrencyPair {
    @Attribute(.unique) var id: UUID
    var baseCurrency: String
    
    init(baseCurrency: String) {
        self.id = UUID()
        self.baseCurrency = baseCurrency
    }
}
```

### UIKit Navigation to NavigationStack

```swift
// OLD: UIKit Navigation
navigationController?.pushViewController(detailVC, animated: true)

// NEW: SwiftUI NavigationStack
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            // Root view
        }
        .navigationDestination(for: CurrencyPair.self) { pair in
            CurrencyDetailView(pair: pair)
        }
    }
}
```

## Risk Management

### Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| WebSocket stability with URLSession | High | Extensive testing, fallback to polling |
| SwiftUI performance with large lists | Medium | Lazy loading, List optimization |
| Swift Charts with large datasets | Medium | Data sampling, update throttling |
| Core Data migration complexity | High | Phased migration, data validation |

### Business Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| iOS 15+ requirement excludes users | High | Analyze user base iOS versions |
| Feature parity challenges | Medium | Early prototyping of complex features |
| Extended timeline | Medium | MVP approach, phased releases |

## Timeline & Resources

### Development Timeline (14-18 weeks)

**Phase 1: Foundation & iOS 18 Setup (Weeks 1-3)**
- Swift 6 project initialization with strict concurrency
- AppDelegate-free SwiftUI App architecture
- SwiftData model implementation
- @Observable architecture setup
- App Intents foundation
- Native lifecycle management setup

**Phase 2: Data Layer with Modern APIs (Weeks 4-5)**
- URLSession with async/await implementation
- SwiftData persistence layer
- Background task configuration
- Firebase SDK 11+ integration

**Phase 3: Core Features with iOS 18 Enhancements (Weeks 6-10)**
- SwiftUI 6.0 watchlist with enhanced animations
- Real-time price streaming with Live Activities
- Interactive widgets implementation
- Alert system with interactive notifications

**Phase 4: iOS 18 Exclusive Features (Weeks 11-13)**
- Control Center integration
- Dynamic Island implementation
- App Intents and Shortcuts
- Siri integration

**Phase 5: Advanced Features (Weeks 14-15)**
- Swift Charts 6.0 with enhanced interactions
- Focus Modes integration
- Advanced localization with String Catalogs
- Cross-platform preparation (visionOS consideration)

**Phase 6: Testing & Polish (Weeks 16-17)**
- iOS 18 specific testing
- Performance optimization for new APIs
- Accessibility enhancements
- Beta testing with TestFlight

**Phase 7: App Store Preparation (Week 18)**
- iOS 18 feature highlights
- App Store optimization
- Release preparation

### Resource Requirements

- **Development Team**:
  - 2-3 Senior iOS Developers (SwiftUI 6.0, iOS 18, Swift 6 expertise)
  - 1 UI/UX Designer (iOS 18 design language experience)
  - 1 QA Engineer (iOS 18 testing protocols)
  - 1 DevOps Engineer (modern CI/CD with Xcode Cloud)
  
- **Infrastructure**:
  - Xcode Cloud for CI/CD with iOS 18 support
  - TestFlight beta testing with iOS 18 features
  - Analytics with iOS 18 specific metrics
  - App Store Connect enhanced monitoring

### Success Metrics

- Feature parity plus iOS 18 enhancements
- Performance improvements (50%+ faster app launch, 30% less memory usage)
- Crash-free rate > 99.7% (iOS 18 stability)
- User engagement with Live Activities and Control Center
- Widget usage and interaction rates
- Siri shortcut adoption
- App Store featuring for iOS 18 showcase
- Code maintainability with Swift 6 strict concurrency

## Conclusion

This comprehensive iOS 18 migration plan provides a complete roadmap for rebuilding Bitpal as a cutting-edge SwiftUI 6.0 application. By targeting iOS 18+, the app will leverage the latest platform capabilities including Live Activities, Control Center integration, App Intents, and Interactive Widgets. The modern Swift 6 architecture with strict concurrency will ensure excellent performance and maintainability.

### iOS 18 Competitive Advantages

- **Live Activities**: Real-time price updates on Lock Screen and Dynamic Island
- **Control Center**: Instant price checking without opening the app
- **Interactive Widgets**: User engagement directly from Home Screen
- **Siri Integration**: Voice-activated price queries and alert creation
- **Performance**: Native SwiftUI 6.0 and SwiftData for optimal efficiency
- **Future-Proof Architecture**: AppDelegate-free design ready for iOS 26+
- **Cross-Platform Ready**: Foundation for visionOS and macOS expansion

### Next Steps

1. **Team Assembly**: Hire iOS 18 and Swift 6 experienced developers
2. **User Analysis**: Confirm target audience has iOS 18+ adoption
3. **Design Language**: Create iOS 18-specific design system
4. **Development Environment**: Set up Xcode Cloud with iOS 18 support
5. **Phase 1 Kickoff**: Begin Swift 6 foundation implementation

### Key Success Factors

- **iOS 18 First**: Design specifically for iOS 18 capabilities, not backwards compatibility
- **Swift 6 Adoption**: Embrace strict concurrency from day one
- **User Experience**: Focus on iOS 18 exclusive features that delight users
- **Performance Benchmarks**: Achieve measurable improvements over legacy version
- **App Store Positioning**: Target iOS 18 feature showcases and recommendations
- **Future Scalability**: Build foundation for multi-platform expansion

### Expected Outcomes

The modernized Bitpal will be positioned as a premium cryptocurrency tracking app that showcases the best of iOS 18, potentially earning App Store editorial features and significantly improving user engagement through native platform integration.