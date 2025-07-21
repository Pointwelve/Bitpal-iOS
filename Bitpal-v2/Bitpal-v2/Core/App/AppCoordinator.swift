//
//  AppCoordinator.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Observation
import SwiftData
import SwiftUI
import OSLog

@MainActor
@Observable
final class AppCoordinator {
    static let shared = AppCoordinator()
    
    // MARK: - Properties
    
    // Initialization state
    private(set) var isInitialized = false
    private(set) var initializationError: Error?
    
    // Core Services - initialized on demand for better performance
    private var _priceStreamService: PriceStreamService?
    private var _alertService: AlertService?
    private var _currencySearchService: CurrencySearchService?
    private var _technicalAnalysisService: TechnicalAnalysisService?
    private var _historicalDataService: HistoricalDataService?
    
    // Public service accessors
    var priceStreamService: PriceStreamService {
        if let service = _priceStreamService {
            return service
        }
        let service = PriceStreamService.shared
        _priceStreamService = service
        return service
    }
    
    var alertService: AlertService {
        if let service = _alertService {
            return service
        }
        let service = AlertService.shared
        _alertService = service
        return service
    }
    
    var currencySearchService: CurrencySearchService {
        if let service = _currencySearchService {
            return service
        }
        let service = CurrencySearchService.shared
        _currencySearchService = service
        return service
    }
    
    var technicalAnalysisService: TechnicalAnalysisService {
        if let service = _technicalAnalysisService {
            return service
        }
        let service = TechnicalAnalysisService.shared
        _technicalAnalysisService = service
        return service
    }
    
    var historicalDataService: HistoricalDataService {
        if let service = _historicalDataService {
            return service
        }
        let service = HistoricalDataService.shared
        _historicalDataService = service
        return service
    }
    
    // SwiftData Container - lazy loaded with proper error handling
    private var _modelContainer: ModelContainer?
    private let logger = Logger(subsystem: "com.pointwelve.Bitpal-v2", category: "AppCoordinator")
    
    var modelContainer: ModelContainer {
        get throws {
            if let container = _modelContainer {
                return container
            }
            
            let container = try createModelContainer()
            _modelContainer = container
            return container
        }
    }
    
    // MARK: - Configuration
    
    private struct AppConfiguration {
        static let apiHost = "https://data-api.coindesk.com"
        static let functionsHost = "https://data-api.coindesk.com"
        static let defaultAPIKey = "a10b6019948f0cd3183025f3f306083209665c4267fcd01db73a4a58e6123c2d"
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Initialization
    
    private init() {
        logger.info("AppCoordinator initializing...")
        
        Task {
            await performInitialization()
        }
    }
    
    private func performInitialization() async {
        do {
            logger.info("Starting service initialization...")
            try await initializeServices()
            isInitialized = true
            logger.info("AppCoordinator initialization completed successfully")
        } catch {
            logger.error("AppCoordinator initialization failed: \(error.localizedDescription)")
            initializationError = error
        }
    }
    
    // MARK: - Service Management
    
    private func initializeServices() async throws {
        // Get model context with proper error handling
        let context: ModelContext
        do {
            context = try modelContainer.mainContext
        } catch {
            logger.error("Failed to create model context: \(error.localizedDescription)")
            throw AppCoordinatorError.modelContextCreationFailed(error)
        }
        
        // Initialize services in optimal order with error handling
        await withTaskGroup(of: Void.self) { group in
            // Core configuration first
            group.addTask {
                await self.loadConfiguration(context: context)
            }
            
            // Then initialize services
            group.addTask {
                await self.initializePriceStreamService(context: context)
            }
            
            group.addTask {
                await self.initializeAlertService(context: context)
            }
            
            group.addTask {
                await self.initializeTechnicalAnalysisService(context: context)
            }
            
            group.addTask {
                await self.initializeHistoricalDataService(context: context)
            }
        }
        
        // Load user preferences (can run independently)
        await loadUserPreferences()
        
        // Load initial data only after services are ready
        await loadInitialPrices(context: context)
    }
    
    private func initializePriceStreamService(context: ModelContext) async {
        priceStreamService.setModelContext(context)
        logger.debug("PriceStreamService initialized")
    }
    
    private func initializeAlertService(context: ModelContext) async {
        alertService.setModelContext(context)
        logger.debug("AlertService initialized")
    }
    
    private func initializeTechnicalAnalysisService(context: ModelContext) async {
        technicalAnalysisService.setModelContext(context)
        logger.debug("TechnicalAnalysisService initialized")
    }
    
    private func initializeHistoricalDataService(context: ModelContext) async {
        historicalDataService.setModelContext(context)
        logger.debug("HistoricalDataService initialized")
    }
    
    // MARK: - Model Container
    
    private func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            CurrencyPair.self,
            Currency.self,
            Exchange.self,
            Alert.self,
            HistoricalPrice.self,
            Configuration.self,
            Watchlist.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none // Disable CloudKit for now
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            logger.info("ModelContainer created successfully")
            return container
        } catch {
            logger.error("Failed to create ModelContainer: \(error.localizedDescription)")
            throw AppCoordinatorError.modelContainerCreationFailed(error)
        }
    }
    
    // MARK: - Configuration Management
    
    private func loadConfiguration(context: ModelContext) async {
        do {
            let config = try await loadOrCreateConfiguration(context: context)
            await configureServices(with: config)
            logger.info("Configuration loaded successfully")
        } catch {
            logger.error("Failed to load configuration: \(error.localizedDescription)")
        }
    }
    
    private func loadOrCreateConfiguration(context: ModelContext) async throws -> Configuration {
        let descriptor = FetchDescriptor<Configuration>()
        let configurations = try context.fetch(descriptor)
        
        let config: Configuration
        if configurations.isEmpty {
            config = createDefaultConfiguration()
            context.insert(config)
            logger.info("Created default configuration")
        } else {
            config = configurations.first!
            updateConfigurationIfNeeded(config)
            logger.info("Loaded existing configuration")
        }
        
        try context.save()
        return config
    }
    
    private func createDefaultConfiguration() -> Configuration {
        let config = Configuration()
        config.update(
            apiHost: AppConfiguration.apiHost,
            functionsHost: AppConfiguration.functionsHost,
            apiKey: AppConfiguration.defaultAPIKey
        )
        return config
    }
    
    private func updateConfigurationIfNeeded(_ config: Configuration) {
        // Update configuration with latest settings if needed
        if config.apiHost != AppConfiguration.apiHost ||
           config.functionsHost != AppConfiguration.functionsHost {
            config.update(
                apiHost: AppConfiguration.apiHost,
                functionsHost: AppConfiguration.functionsHost,
                apiKey: config.apiKey.isEmpty ? AppConfiguration.defaultAPIKey : config.apiKey
            )
            logger.info("Updated configuration with new API settings")
        }
    }
    
    private func configureServices(with config: Configuration) async {
        // Configure services with the loaded configuration
        await priceStreamService.setAPIKey(config.apiKey)
        logger.debug("Services configured with API key")
    }
    
    // MARK: - Data Loading
    
    private func loadUserPreferences() async {
        // User preferences implementation
        // TODO: Implement UserPreferences model properly
        logger.debug("User preferences loading skipped (not implemented)")
    }
    
    private func loadInitialPrices(context: ModelContext) async {
        do {
            let currencyPairs = try await fetchExistingCurrencyPairs(context: context)
            
            guard !currencyPairs.isEmpty else {
                logger.info("No currency pairs found, skipping initial price loading")
                return
            }
            
            logger.info("Loading initial prices for \(currencyPairs.count) currency pairs")
            
            // Use retry mechanism for initial price loading
            try await retryOperation {
                try await self.priceStreamService.fetchLatestPrices(for: currencyPairs)
            }
            
            // Start streaming for existing pairs (non-blocking)
            Task {
                await self.priceStreamService.startStreaming(for: currencyPairs)
            }
            
            logger.info("Initial price loading completed successfully")
        } catch {
            logger.error("Failed to load initial prices: \(error.localizedDescription)")
        }
    }
    
    private func fetchExistingCurrencyPairs(context: ModelContext) async throws -> [CurrencyPair] {
        let descriptor = FetchDescriptor<CurrencyPair>()
        return try context.fetch(descriptor)
    }
    
    // MARK: - Retry Mechanism
    
    private func retryOperation<T>(
        maxAttempts: Int = AppConfiguration.maxRetryAttempts,
        delay: TimeInterval = AppConfiguration.retryDelay,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                logger.warning("Operation failed (attempt \(attempt)/\(maxAttempts)): \(error.localizedDescription)")
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppCoordinatorError.retryLimitExceeded
    }
    
    // MARK: - Cleanup
    
    deinit {
        logger.info("AppCoordinator deinitializing...")
        // Cleanup will be handled by service deinit methods
    }
}

// MARK: - Error Types

enum AppCoordinatorError: LocalizedError {
    case modelContainerCreationFailed(Error)
    case modelContextCreationFailed(Error)
    case configurationLoadFailed(Error)
    case serviceInitializationFailed(String, Error)
    case retryLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .modelContainerCreationFailed(let error):
            return "Failed to create model container: \(error.localizedDescription)"
        case .modelContextCreationFailed(let error):
            return "Failed to create model context: \(error.localizedDescription)"
        case .configurationLoadFailed(let error):
            return "Failed to load configuration: \(error.localizedDescription)"
        case .serviceInitializationFailed(let serviceName, let error):
            return "Failed to initialize \(serviceName): \(error.localizedDescription)"
        case .retryLimitExceeded:
            return "Operation failed after maximum retry attempts"
        }
    }
}

// MARK: - Environment Key

private struct AppCoordinatorKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: AppCoordinator = AppCoordinator.shared
}

extension EnvironmentValues {
    var appCoordinator: AppCoordinator {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

// MARK: - Public Extensions

extension AppCoordinator {
    /// Checks if the coordinator is ready for use
    var isReady: Bool {
        isInitialized && initializationError == nil
    }
    
    /// Provides a safe way to access the model container
    func safeModelContainer() -> ModelContainer? {
        do {
            return try modelContainer
        } catch {
            logger.error("Failed to access model container: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Restarts the initialization process if it failed
    func retryInitialization() async {
        guard !isInitialized else { return }
        
        logger.info("Retrying AppCoordinator initialization...")
        initializationError = nil
        await performInitialization()
    }
    
    /// Gracefully shuts down all services
    func shutdown() async {
        logger.info("Shutting down AppCoordinator...")
        
        // Stop streaming services if initialized
        if _priceStreamService != nil {
            await priceStreamService.stopStreaming()
        }
        
        // Cancel any pending operations
        // Additional cleanup can be added here as needed
        
        logger.info("AppCoordinator shutdown completed")
    }
}