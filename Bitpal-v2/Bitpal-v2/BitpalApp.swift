//
//  Bitpal_v2App.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct BitpalApp: App {
    let appCoordinator = AppCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appCoordinator)
                .environment(appCoordinator.priceStreamService)
                .environment(appCoordinator.alertService)
                .environment(appCoordinator.currencySearchService)
                .environment(appCoordinator.technicalAnalysisService)
                .environment(appCoordinator.historicalDataService)
                .modelContainer(for: [
                    CurrencyPair.self,
                    Currency.self,
                    Exchange.self,
                    Alert.self,
                    HistoricalPrice.self,
                    Configuration.self,
                    Watchlist.self
                ])
                .task {
                    await setupApp()
                }
        }
    }
    
    private func setupApp() async {
        // Request notification permissions
        await requestNotificationPermissions()
        
        // Wait for AppCoordinator to initialize
        while !appCoordinator.isReady {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            if granted {
                print("Notification permissions granted")
            }
        } catch {
            print("Failed to request notification permissions: \(error)")
        }
    }
}
