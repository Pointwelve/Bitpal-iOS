//
//  AlertService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Observation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
@Observable
final class AlertService {
    static let shared = AlertService()
    
    private(set) var alerts: [Alert] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let apiClient = APIClient.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        setupNotificationHandling()
    }
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        Task {
            await loadAlerts()
        }
    }
    
    // MARK: - Alert CRUD Operations
    
    func loadAlerts() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<Alert>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            alerts = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load alerts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createAlert(
        for currencyPair: CurrencyPair,
        comparison: AlertComparison,
        targetPrice: Double,
        isEnabled: Bool = true
    ) async throws {
        guard let context = modelContext else {
            throw AlertError.contextNotAvailable
        }
        
        // Validate input
        guard targetPrice > 0 else {
            throw AlertError.invalidTargetPrice
        }
        
        // Check for duplicate alerts
        let existingAlerts = try context.fetch(FetchDescriptor<Alert>())
        let duplicateExists = existingAlerts.contains { alert in
            alert.currencyPair?.id == currencyPair.id &&
            alert.comparison == comparison &&
            alert.targetPrice == targetPrice
        }
        
        if duplicateExists {
            throw AlertError.duplicateAlert
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create local alert
            let alert = Alert(
                currencyPair: currencyPair,
                comparison: comparison,
                targetPrice: targetPrice,
                isEnabled: isEnabled
            )
            
            context.insert(alert)
            try context.save()
            
            // Sync with backend API
            try await syncAlertWithBackend(alert, action: .create)
            
            // Schedule local notification if needed
            if isEnabled {
                await scheduleLocalNotification(for: alert)
            }
            
            await loadAlerts()
            
        } catch let apiError as NetworkError {
            // If API fails, remove the local alert
            if let alertToDelete = alerts.first(where: { $0.targetPrice == targetPrice }) {
                context.delete(alertToDelete)
            }
            try? context.save()
            throw AlertError.networkError(apiError)
        } catch {
            throw AlertError.creationFailed(error)
        }
        
        isLoading = false
    }
    
    func updateAlert(_ alert: Alert, isEnabled: Bool) async throws {
        guard let context = modelContext else {
            throw AlertError.contextNotAvailable
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            alert.isEnabled = isEnabled
            alert.lastModified = Date()
            
            try context.save()
            
            // Sync with backend
            try await syncAlertWithBackend(alert, action: .update)
            
            // Update local notification
            if isEnabled {
                await scheduleLocalNotification(for: alert)
            } else {
                await cancelLocalNotification(for: alert)
            }
            
            await loadAlerts()
            
        } catch {
            throw AlertError.updateFailed(error)
        }
        
        isLoading = false
    }
    
    func deleteAlert(_ alert: Alert) async throws {
        guard let context = modelContext else {
            throw AlertError.contextNotAvailable
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Sync deletion with backend first
            try await syncAlertWithBackend(alert, action: .delete)
            
            // Cancel local notification
            await cancelLocalNotification(for: alert)
            
            // Remove from local storage
            context.delete(alert)
            try context.save()
            
            await loadAlerts()
            
        } catch {
            throw AlertError.deletionFailed(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Alert Triggering
    
    func checkAlerts(with streamPrice: StreamPrice) async {
        guard let currentPrice = streamPrice.price else { return }
        
        let enabledAlerts = alerts.filter { alert in
            alert.isEnabled &&
            alert.currencyPair?.baseCurrency?.symbol == streamPrice.baseCurrency &&
            alert.currencyPair?.quoteCurrency?.symbol == streamPrice.quoteCurrency &&
            alert.currencyPair?.exchange?.id == streamPrice.exchange
        }
        
        for alert in enabledAlerts {
            let shouldTrigger = evaluateAlertCondition(alert, currentPrice: currentPrice)
            
            if shouldTrigger && !isRecentlyTriggered(alert) {
                await triggerAlert(alert, currentPrice: currentPrice)
            }
        }
    }
    
    private func evaluateAlertCondition(_ alert: Alert, currentPrice: Double) -> Bool {
        switch alert.comparison {
        case .above:
            return currentPrice >= alert.targetPrice
        case .below:
            return currentPrice <= alert.targetPrice
        }
    }
    
    private func isRecentlyTriggered(_ alert: Alert) -> Bool {
        guard let lastTriggered = alert.lastTriggered else { return false }
        // Prevent spam - only trigger once per hour
        return Date().timeIntervalSince(lastTriggered) < 3600
    }
    
    private func triggerAlert(_ alert: Alert, currentPrice: Double) async {
        guard let context = modelContext else { return }
        
        // Update alert trigger time
        alert.lastTriggered = Date()
        try? context.save()
        
        // Send local notification
        await sendLocalNotification(for: alert, currentPrice: currentPrice)
        
        // Update widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        // Analytics (if needed)
        logAlertTriggered(alert)
    }
    
    // MARK: - Backend Synchronization
    
    private enum AlertAction {
        case create, update, delete
    }
    
    private func syncAlertWithBackend(_ alert: Alert, action: AlertAction) async throws {
        guard let currencyPair = alert.currencyPair else {
            throw AlertError.invalidCurrencyPair
        }
        
        switch action {
        case .create:
            let _ = CreateAlertRequest(
                pair: currencyPair.displayName,
                exchange: currencyPair.exchange?.id ?? "",
                comparison: alert.comparison.rawValue,
                reference: alert.targetPrice,
                isEnabled: alert.isEnabled
            )
            let _: CreateAlertResponse = try await apiClient.request(CryptoAPIEndpoint.createAlert(APICreateAlertRequest(
                currencyPairId: currencyPair.id,
                comparison: alert.comparison.rawValue,
                targetPrice: alert.targetPrice,
                message: alert.message,
                isEnabled: alert.isEnabled
            )))
            
        case .update:
            let _ = UpdateAlertRequest(
                id: alert.id,
                isEnabled: alert.isEnabled
            )
            let _: UpdateAlertResponse = try await apiClient.request(CryptoAPIEndpoint.updateAlert(alert.id, APIUpdateAlertRequest(
                comparison: alert.comparison.rawValue,
                targetPrice: alert.targetPrice,
                message: alert.message,
                isEnabled: alert.isEnabled
            )))
            
        case .delete:
            let _: DeleteAlertResponse = try await apiClient.request(CryptoAPIEndpoint.deleteAlert(alert.id))
        }
    }
    
    // MARK: - Local Notifications
    
    private func setupNotificationHandling() {
        Task {
            await requestNotificationPermissions()
        }
    }
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            
            if granted {
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
        
        let disableAction = UNNotificationAction(
            identifier: "DISABLE_ALERT",
            title: "Disable Alert",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "PRICE_ALERT",
            actions: [viewAction, disableAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    private func scheduleLocalNotification(for alert: Alert) async {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "PRICE_ALERT"
        content.userInfo = ["alert_id": alert.id]
        
        // Schedule immediately (will be triggered by price check)
        let request = UNNotificationRequest(
            identifier: alert.id,
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    private func sendLocalNotification(for alert: Alert, currentPrice: Double) async {
        guard let currencyPair = alert.currencyPair else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Price Alert Triggered"
        content.body = """
        \(currencyPair.displayName) is now \(alert.comparison.symbol) \(alert.targetPrice.formatted(.currency(code: "USD")))
        Current price: \(currentPrice.formatted(.currency(code: "USD")))
        """
        content.sound = .default
        content.categoryIdentifier = "PRICE_ALERT"
        content.userInfo = [
            "alert_id": alert.id,
            "currency_pair": currencyPair.displayName,
            "current_price": currentPrice
        ]
        
        let request = UNNotificationRequest(
            identifier: "triggered_\(alert.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    private func cancelLocalNotification(for alert: Alert) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [alert.id]
        )
    }
    
    // MARK: - Utility
    
    func getUnreadAlertCount() async -> Int {
        return alerts.filter { $0.lastTriggered != nil && $0.isEnabled }.count
    }
    
    func markAlertAsRead(_ alertId: String) async {
        // Implementation for marking alerts as read
        // This could be used for managing notification badges
    }
    
    private func logAlertTriggered(_ alert: Alert) {
        // Analytics logging for alert triggers
        print("Alert triggered: \(alert.id) at \(Date())")
    }
}

// MARK: - Error Handling

enum AlertError: LocalizedError {
    case contextNotAvailable
    case invalidTargetPrice
    case duplicateAlert
    case invalidCurrencyPair
    case networkError(NetworkError)
    case creationFailed(Error)
    case updateFailed(Error)
    case deletionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .invalidTargetPrice:
            return "Target price must be greater than 0"
        case .duplicateAlert:
            return "An alert for this price already exists"
        case .invalidCurrencyPair:
            return "Invalid currency pair for alert"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .creationFailed(let error):
            return "Failed to create alert: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update alert: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete alert: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Request/Response Models

struct CreateAlertRequest: Codable {
    let pair: String
    let exchange: String
    let comparison: String
    let reference: Double
    let isEnabled: Bool
}

struct CreateAlertResponse: Codable {
    let id: String
    let success: Bool
}

struct UpdateAlertRequest: Codable {
    let id: String
    let isEnabled: Bool
}

struct UpdateAlertResponse: Codable {
    let success: Bool
}

struct DeleteAlertResponse: Codable {
    let success: Bool
}