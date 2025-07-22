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
    @State private var modelContainer: ModelContainer?
    
    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .environment(appCoordinator)
                    .environment(appCoordinator.priceStreamService)
                    .environment(appCoordinator.alertService)
                    .environment(appCoordinator.currencySearchService)
                    .environment(appCoordinator.technicalAnalysisService)
                    .environment(appCoordinator.historicalDataService)
                    .modelContainer(container)
                    .task {
                        await setupApp()
                    }
            } else {
                ProgressView("Loading...")
                    .task {
                        await loadModelContainer()
                    }
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
    
    private func loadModelContainer() async {
        do {
            modelContainer = try appCoordinator.modelContainer
        } catch {
            print("Failed to load model container: \(error)")
            // In a production app, you might want to show an error view
            // For now, we'll keep trying
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await loadModelContainer()
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
