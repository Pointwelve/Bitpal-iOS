//
//  WatchlistViewModel.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class WatchlistViewModel {
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let priceStreamService = PriceStreamService.shared
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        priceStreamService.setModelContext(context)
    }
    
    func startPriceStreaming(for pairs: [CurrencyPair]) async {
        guard !pairs.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // First fetch latest prices
            try await priceStreamService.fetchLatestPrices(for: pairs)
            
            // Then start streaming
            await priceStreamService.startStreaming(for: pairs)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startPriceStreamingIfNeeded(for pairs: [CurrencyPair]) async {
        guard !pairs.isEmpty else { return }
        
        // Check if streaming is already active
        if priceStreamService.isStreaming {
            print("ℹ️ Price streaming already active, ensuring all pairs are subscribed")
            
            // Ensure all current pairs are subscribed
            for pair in pairs {
                await priceStreamService.subscribe(to: pair)
            }
        } else {
            print("🔄 Starting fresh price streaming for watchlist")
            await startPriceStreaming(for: pairs)
        }
    }
    
    func refreshPrices(for pairs: [CurrencyPair]) async {
        guard !pairs.isEmpty else { return }
        
        do {
            try await priceStreamService.fetchLatestPrices(for: pairs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addCurrencyPair(_ pair: CurrencyPair) {
        guard let context = modelContext else { return }
        
        context.insert(pair)
        
        do {
            try context.save()
            
            // Subscribe to price updates
            Task {
                await priceStreamService.subscribe(to: pair)
            }
        } catch {
            errorMessage = "Failed to add currency pair: \(error.localizedDescription)"
        }
    }
    
    func removeCurrencyPair(_ pair: CurrencyPair) {
        guard let context = modelContext else { return }
        
        context.delete(pair)
        
        do {
            try context.save()
            
            // Unsubscribe from price updates
            Task {
                await priceStreamService.unsubscribe(from: pair)
            }
        } catch {
            errorMessage = "Failed to remove currency pair: \(error.localizedDescription)"
        }
    }
    
    func movePair(from sourceIndex: Int, to destinationIndex: Int, in pairs: [CurrencyPair]) {
        guard let context = modelContext,
              sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < pairs.count,
              destinationIndex >= 0, destinationIndex <= pairs.count else {
            return
        }
        
        var mutablePairs = pairs
        let pair = mutablePairs.remove(at: sourceIndex)
        mutablePairs.insert(pair, at: destinationIndex)
        
        // Update sort orders
        for (index, pair) in mutablePairs.enumerated() {
            pair.sortOrder = index
        }
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to reorder pairs: \(error.localizedDescription)"
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}