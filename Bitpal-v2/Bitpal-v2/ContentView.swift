//
//  ContentView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData
import OSLog

@MainActor
@Observable
final class ContentViewModel {
    private let logger = Logger(subsystem: "com.pointwelve.Bitpal-v2", category: "ContentView")
    
    // Initialization state
    private(set) var isInitialized = false
    private(set) var initializationError: Error?
    private(set) var isInitializing = false
    
    // Tab management
    var selectedTab: Tab = .watchlist
    
    // MARK: - Tab Definition
    
    enum Tab: Int, CaseIterable {
        case watchlist = 0
        case alerts = 1
        case portfolio = 2
        case settings = 3
        
        var title: String {
            switch self {
            case .watchlist: return "Watchlist"
            case .alerts: return "Alerts"
            case .portfolio: return "Portfolio"
            case .settings: return "Settings"
            }
        }
        
        var iconName: String {
            switch self {
            case .watchlist: return "chart.line.uptrend.xyaxis"
            case .alerts: return "bell"
            case .portfolio: return "briefcase"
            case .settings: return "gear"
            }
        }
        
        var accessibilityLabel: String {
            switch self {
            case .watchlist: return "Watchlist tab"
            case .alerts: return "Alerts tab"
            case .portfolio: return "Portfolio tab"
            case .settings: return "Settings tab"
            }
        }
    }
    
    // MARK: - Initialization
    
    func initializeApp(with modelContext: ModelContext) async {
        guard !isInitialized && !isInitializing else {
            logger.info("App already initialized or initializing")
            return
        }
        
        isInitializing = true
        logger.info("Starting app initialization...")
        
        do {
            // Initialize in parallel for better performance
            async let configTask = initializeConfiguration(modelContext: modelContext)
            async let currenciesTask = initializeDefaultCurrencies(modelContext: modelContext)
            
            // Wait for both tasks to complete
            try await configTask
            try await currenciesTask
            
            isInitialized = true
            initializationError = nil
            logger.info("App initialization completed successfully")
            
        } catch {
            logger.error("App initialization failed: \(error.localizedDescription)")
            initializationError = error
        }
        
        isInitializing = false
    }
    
    func retryInitialization(with modelContext: ModelContext) async {
        logger.info("Retrying app initialization...")
        isInitialized = false
        initializationError = nil
        await initializeApp(with: modelContext)
    }
    
    // MARK: - Private Initialization Methods
    
    private func initializeConfiguration(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Configuration>()
        
        let configurations = try modelContext.fetch(descriptor)
        if configurations.isEmpty {
            let defaultConfig = Configuration()
            modelContext.insert(defaultConfig)
            try modelContext.save()
            logger.info("Created default configuration")
        } else {
            logger.info("Configuration already exists")
        }
    }
    
    private func initializeDefaultCurrencies(modelContext: ModelContext) async throws {
        let currencyDescriptor = FetchDescriptor<Currency>()
        let currencies = try modelContext.fetch(currencyDescriptor)
        
        if currencies.isEmpty {
            // Create default currencies
            let defaultCurrencies = createDefaultCurrencies()
            for currency in defaultCurrencies {
                modelContext.insert(currency)
            }
            
            // Create default exchange
            let exchange = Exchange(id: "COINDESK", name: "CoinDesk", displayName: "CoinDesk")
            modelContext.insert(exchange)
            
            try modelContext.save()
            logger.info("Created \(defaultCurrencies.count) default currencies and exchange")
        } else {
            logger.info("Currencies already exist (\(currencies.count) found)")
        }
    }
    
    private func createDefaultCurrencies() -> [Currency] {
        return [
            Currency.bitcoin(),
            Currency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ"),
            Currency.usd(),
            Currency(id: "eur", name: "Euro", symbol: "EUR", displaySymbol: "€"),
            Currency(id: "gbp", name: "British Pound", symbol: "GBP", displaySymbol: "£")
        ]
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) private var appCoordinator
    @State private var viewModel = ContentViewModel()
    @State private var showingErrorAlert = false
    
    var body: some View {
        Group {
            if viewModel.isInitializing {
                loadingView
            } else if let error = viewModel.initializationError {
                errorView(error: error)
            } else {
                mainTabView
            }
        }
        .task {
            await viewModel.initializeApp(with: modelContext)
        }
        .alert("Initialization Error", isPresented: $showingErrorAlert) {
            Button("Retry") {
                Task {
                    await viewModel.retryInitialization(with: modelContext)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let error = viewModel.initializationError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Bitpal...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading application")
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Initialization Failed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.retryInitialization(with: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Initialization failed. Retry button available.")
    }
    
    private var mainTabView: some View {
        TabView(selection: Binding(
            get: { viewModel.selectedTab.rawValue },
            set: { newValue in
                if let tab = ContentViewModel.Tab(rawValue: newValue) {
                    viewModel.selectedTab = tab
                }
            }
        )) {
            ForEach(ContentViewModel.Tab.allCases, id: \.rawValue) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Image(systemName: tab.iconName)
                        Text(tab.title)
                    }
                    .tag(tab.rawValue)
                    .accessibilityLabel(tab.accessibilityLabel)
            }
        }
        .accentColor(.blue)
    }
    
    @ViewBuilder
    private func tabContent(for tab: ContentViewModel.Tab) -> some View {
        switch tab {
        case .watchlist:
            LazyView {
                WatchlistView()
            }
        case .alerts:
            LazyView {
                AlertsView()
            }
        case .portfolio:
            LazyView {
                PortfolioView()
            }
        case .settings:
            LazyView {
                SettingsView()
            }
        }
    }
}

// MARK: - Lazy View Wrapper

struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Query private var configurations: [Configuration]
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) private var appCoordinator
    @State private var showingAPIKeyField = false
    @State private var tempAPIKey = ""
    
    var body: some View {
        NavigationStack {
            Form {
                appStatusSection
                apiConfigurationSection
                appearanceSection
                notificationsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Settings Sections
    
    private var appStatusSection: some View {
        Section("App Status") {
            HStack {
                Text("Initialization")
                Spacer()
                if appCoordinator.isReady {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Initializing", systemImage: "clock")
                        .foregroundColor(.orange)
                }
            }
            
            if let error = appCoordinator.initializationError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button("Retry Initialization") {
                    Task {
                        await appCoordinator.retryInitialization()
                    }
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var apiConfigurationSection: some View {
        Section("API Configuration") {
            if let config = configurations.first {
                HStack {
                    Text("API Key")
                    Spacer()
                    if showingAPIKeyField {
                        SecureField("Enter API Key", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                saveAPIKey()
                            }
                    } else {
                        Text(config.apiKey.isEmpty ? "Not Set" : "••••••••")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if showingAPIKeyField {
                        Button("Save") {
                            saveAPIKey()
                        }
                        .disabled(tempAPIKey.isEmpty)
                        
                        Button("Cancel") {
                            showingAPIKeyField = false
                            tempAPIKey = ""
                        }
                    } else {
                        Button("Edit") {
                            showingAPIKeyField = true
                            tempAPIKey = config.apiKey
                        }
                    }
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            if let prefs = preferences.first {
                Picker("Theme", selection: createBinding(
                    get: { prefs.theme },
                    set: { prefs.theme = $0 }
                )) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                
                Picker("Currency", selection: createBinding(
                    get: { prefs.currency },
                    set: { prefs.currency = $0 }
                )) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("JPY").tag("JPY")
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            if let prefs = preferences.first {
                Toggle("Enable Notifications", isOn: createBinding(
                    get: { prefs.notificationsEnabled },
                    set: { prefs.notificationsEnabled = $0 }
                ))
                
                Toggle("Price Alerts", isOn: createBinding(
                    get: { prefs.priceAlertsEnabled },
                    set: { prefs.priceAlertsEnabled = $0 }
                ))
                .disabled(!prefs.notificationsEnabled)
                
                Toggle("News Alerts", isOn: createBinding(
                    get: { prefs.newsAlertsEnabled },
                    set: { prefs.newsAlertsEnabled = $0 }
                ))
                .disabled(!prefs.notificationsEnabled)
                
                Toggle("Biometric Authentication", isOn: createBinding(
                    get: { prefs.biometricAuthEnabled },
                    set: { prefs.biometricAuthEnabled = $0 }
                ))
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            if let config = configurations.first {
                SettingsRow(title: "Version", value: config.version)
                SettingsRow(title: "Company", value: config.companyName)
                SettingsRow(title: "API Host", value: config.apiHost)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createBinding<T>(get: @escaping () -> T, set: @escaping (T) -> Void) -> Binding<T> {
        Binding(
            get: get,
            set: { newValue in
                set(newValue)
                saveModelContext()
            }
        )
    }
    
    private func saveAPIKey() {
        guard let config = configurations.first else { return }
        config.apiKey = tempAPIKey
        saveModelContext()
        showingAPIKeyField = false
        tempAPIKey = ""
    }
    
    private func saveModelContext() {
        do {
            try modelContext.save()
        } catch {
            // Handle error appropriately
            print("Failed to save settings: \(error)")
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            Currency.self,
            Exchange.self,
            CurrencyPair.self,
            Alert.self,
            HistoricalPrice.self,
            Watchlist.self,
            Configuration.self,
            UserPreferences.self
        ], inMemory: true)
        .environment(AppCoordinator.shared)
}