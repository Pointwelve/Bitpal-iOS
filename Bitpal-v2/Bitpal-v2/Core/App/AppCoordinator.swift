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

@MainActor
@Observable
final class AppCoordinator {
    static let shared = AppCoordinator()
    
    // Core Services
    let priceStreamService = PriceStreamService.shared
    let alertService = AlertService.shared
    let currencySearchService = CurrencySearchService.shared
    let technicalAnalysisService = TechnicalAnalysisService.shared
    let historicalDataService = HistoricalDataService.shared
    
    // SwiftData Container - using private backing property
    private var _modelContainer: ModelContainer?
    
    var modelContainer: ModelContainer {
        if let container = _modelContainer {
            return container
        }
        
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
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            _modelContainer = container
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private init() {
        Task {
            await initializeServices()
        }
    }
    
    func initializeServices() async {
        // Set model contexts for services
        let context = modelContainer.mainContext
        
        priceStreamService.setModelContext(context)
        alertService.setModelContext(context)
        technicalAnalysisService.setModelContext(context)
        historicalDataService.setModelContext(context)
        
        // Load initial configuration
        await loadConfiguration()
        
        // Load user preferences
        await loadUserPreferences()
        
        // Load initial prices for existing currency pairs
        await loadInitialPrices()
    }
    
    private func loadConfiguration() async {
        let context = modelContainer.mainContext
        
        do {
            let descriptor = FetchDescriptor<Configuration>()
            let configurations = try context.fetch(descriptor)
            
            let config: Configuration
            if configurations.isEmpty {
                // Create default configuration
                config = Configuration()
                context.insert(config)
            } else {
                // Update existing configuration with CoinDesk API settings
                config = configurations.first!
                config.update(
                    apiHost: "https://data-api.coindesk.com",
                    functionsHost: "https://data-api.coindesk.com",
                    apiKey: "a10b6019948f0cd3183025f3f306083209665c4267fcd01db73a4a58e6123c2d"
                )
            }
            
            try context.save()
            
            // Set API key for services
            await priceStreamService.setAPIKey(config.apiKey)
            
        } catch {
            print("Failed to load configuration: \(error)")
        }
    }
    
    private func loadUserPreferences() async {
        // User preferences temporarily disabled
        // TODO: Implement UserPreferences model properly
    }
    
    private func loadInitialPrices() async {
        let context = modelContainer.mainContext
        
        do {
            // Fetch all existing currency pairs
            let descriptor = FetchDescriptor<CurrencyPair>()
            let currencyPairs = try context.fetch(descriptor)
            
            if !currencyPairs.isEmpty {
                print("🚀 Loading initial prices for \(currencyPairs.count) currency pairs on app startup")
                
                // Fetch latest prices for all pairs
                try await priceStreamService.fetchLatestPrices(for: currencyPairs)
                
                // Optionally start streaming for all pairs
                await priceStreamService.startStreaming(for: currencyPairs)
                
                print("✅ Initial price loading completed")
            } else {
                print("ℹ️ No currency pairs found, skipping initial price loading")
            }
        } catch {
            print("❌ Failed to load initial prices: \(error)")
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