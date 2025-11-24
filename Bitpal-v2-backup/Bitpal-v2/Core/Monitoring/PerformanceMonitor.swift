//
//  PerformanceMonitor.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import os.log

@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    private struct Operation {
        let name: String
        let startTime: Date
        let id: String
    }
    
    private var activeOperations: [String: Operation] = [:]
    private var completedOperations: [String: TimeInterval] = [:]
    private var networkRequests: [NetworkMetric] = []
    private var memoryReadings: [MemoryReading] = []
    
    private let logger = Logger(subsystem: "com.bitpal.performance", category: "monitor")
    
    @Published private(set) var currentMetrics = PerformanceMetrics(
        averageResponseTime: 0,
        successRate: 0,
        memoryUsage: 0,
        cacheHitRate: 0,
        operationCounts: [:]
    )
    
    private struct NetworkMetric {
        let url: String
        let method: String
        let duration: TimeInterval
        let success: Bool
        let timestamp: Date
    }
    
    private struct MemoryReading {
        let usage: Int
        let timestamp: Date
    }
    
    private init() {
        startPeriodicUpdates()
    }
    
    // MARK: - Operation Tracking
    
    func startOperation(_ name: String) -> String {
        let id = UUID().uuidString
        let operation = Operation(name: name, startTime: Date(), id: id)
        activeOperations[id] = operation
        
        logger.info("Started operation: \(name) [\(id)]")
        return id
    }
    
    func endOperation(_ id: String) {
        guard let operation = activeOperations.removeValue(forKey: id) else {
            logger.warning("Attempted to end unknown operation: \(id)")
            return
        }
        
        let duration = Date().timeIntervalSince(operation.startTime)
        completedOperations[operation.name] = duration
        
        logger.info("Completed operation: \(operation.name) in \(String(format: "%.3f", duration))s [\(id)]")
        
        // Update metrics asynchronously
        Task {
            await updateMetrics()
        }
    }
    
    // MARK: - Memory Monitoring
    
    func logMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        memoryReadings.append(MemoryReading(usage: usage, timestamp: Date()))
        
        // Keep only last 100 readings
        if memoryReadings.count > 100 {
            memoryReadings.removeFirst(memoryReadings.count - 100)
        }
        
        logger.debug("Memory usage: \(usage) MB")
    }
    
    private nonisolated func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / (1024 * 1024) // Convert to MB
        } else {
            logger.error("Failed to get memory usage")
            return 0
        }
    }
    
    // MARK: - Network Monitoring
    
    func logNetworkRequest(_ request: URLRequest, duration: TimeInterval, success: Bool) {
        let metric = NetworkMetric(
            url: request.url?.absoluteString ?? "unknown",
            method: request.httpMethod ?? "GET",
            duration: duration,
            success: success,
            timestamp: Date()
        )
        
        networkRequests.append(metric)
        
        // Keep only last 200 requests
        if networkRequests.count > 200 {
            networkRequests.removeFirst(networkRequests.count - 200)
        }
        
        logger.info("Network request: \(metric.method) \(metric.url) - \(String(format: "%.3f", duration))s [\(success ? "SUCCESS" : "FAILED")]")
    }
    
    // MARK: - Metrics Calculation
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        return currentMetrics
    }
    
    private func updateMetrics() async {
        let avgResponseTime = calculateAverageResponseTime()
        let successRate = calculateSuccessRate()
        let memoryUsage = getCurrentMemoryUsage()
        let operationCounts = calculateOperationCounts()
        
        currentMetrics = PerformanceMetrics(
            averageResponseTime: avgResponseTime,
            successRate: successRate,
            memoryUsage: memoryUsage,
            cacheHitRate: await getCacheHitRate(),
            operationCounts: operationCounts
        )
    }
    
    private func calculateAverageResponseTime() -> TimeInterval {
        let recentRequests = networkRequests.suffix(50) // Last 50 requests
        guard !recentRequests.isEmpty else { return 0 }
        
        let totalTime = recentRequests.reduce(0) { $0 + $1.duration }
        return totalTime / Double(recentRequests.count)
    }
    
    private func calculateSuccessRate() -> Double {
        let recentRequests = networkRequests.suffix(100) // Last 100 requests
        guard !recentRequests.isEmpty else { return 1.0 }
        
        let successCount = recentRequests.filter { $0.success }.count
        return Double(successCount) / Double(recentRequests.count)
    }
    
    private func calculateOperationCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        for operation in activeOperations.values {
            counts[operation.name, default: 0] += 1
        }
        
        return counts
    }
    
    private func getCacheHitRate() async -> Double {
        // Get cache hit rate from CacheManager
        return CacheManager.shared.statistics.overallHitRate
    }
    
    // MARK: - Periodic Updates
    
    private func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.logMemoryUsage()
                await self?.updateMetrics()
            }
        }
    }
    
    // MARK: - Alerts and Thresholds
    
    private func checkPerformanceThresholds() {
        // Memory usage alert
        if self.currentMetrics.memoryUsage > 200 { // 200 MB threshold
            logger.warning("High memory usage detected: \(self.currentMetrics.memoryUsage) MB")
        }
        
        // Response time alert
        if self.currentMetrics.averageResponseTime > 2.0 { // 2 second threshold
            logger.warning("Slow response time detected: \(String(format: "%.3f", self.currentMetrics.averageResponseTime))s")
        }
        
        // Success rate alert
        if self.currentMetrics.successRate < 0.95 { // 95% threshold
            logger.warning("Low success rate detected: \(String(format: "%.1f", self.currentMetrics.successRate * 100))%")
        }
    }
    
    // MARK: - Debugging Helpers
    
    func exportPerformanceReport() -> String {
        var report = "=== Bitpal Performance Report ===\n\n"
        
        report += "Current Metrics:\n"
        report += "- Average Response Time: \(String(format: "%.3f", currentMetrics.averageResponseTime))s\n"
        report += "- Success Rate: \(String(format: "%.1f", currentMetrics.successRate * 100))%\n"
        report += "- Memory Usage: \(currentMetrics.memoryUsage) MB\n"
        report += "- Cache Hit Rate: \(String(format: "%.1f", currentMetrics.cacheHitRate * 100))%\n\n"
        
        report += "Active Operations:\n"
        for operation in activeOperations.values {
            let duration = Date().timeIntervalSince(operation.startTime)
            report += "- \(operation.name): \(String(format: "%.3f", duration))s\n"
        }
        
        report += "\nRecent Network Requests:\n"
        for request in networkRequests.suffix(10) {
            report += "- \(request.method) \(request.url): \(String(format: "%.3f", request.duration))s [\(request.success ? "✓" : "✗")]\n"
        }
        
        return report
    }
}

// MARK: - Performance Tracking Extensions

extension PerformanceMonitor {
    func trackOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        let id = startOperation(name)
        defer { endOperation(id) }
        return try await operation()
    }
    
    func trackOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        let id = startOperation(name)
        defer { endOperation(id) }
        return try operation()
    }
}

// MARK: - SwiftUI Integration

extension PerformanceMonitor {
    var formattedMetrics: [String] {
        return [
            "Avg Response: \(String(format: "%.0f", currentMetrics.averageResponseTime * 1000))ms",
            "Success Rate: \(String(format: "%.0f", currentMetrics.successRate * 100))%",
            "Memory: \(currentMetrics.memoryUsage)MB",
            "Cache Hit: \(String(format: "%.0f", currentMetrics.cacheHitRate * 100))%"
        ]
    }
}