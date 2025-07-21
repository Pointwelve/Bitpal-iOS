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
struct Bitpal_v2App: App {
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
                .modelContainer(appCoordinator.modelContainer)
                .task {
                    await setupApp()
                }
        }
    }
    
    private func setupApp() async {
        // Request notification permissions
        await requestNotificationPermissions()
        
        // Initialize services
        await appCoordinator.initializeServices()
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
