//
//  Watchlist.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Watchlist {
    @Attribute(.unique) var id: String
    var name: String
    var lastModified: Date
    var isDeleted: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var currencyPairs: [CurrencyPair] = []
    
    init(id: String = "default", name: String = "My Watchlist") {
        self.id = id
        self.name = name
        self.lastModified = Date()
        self.isDeleted = false
        self.createdAt = Date()
    }
    
    var sortedPairs: [CurrencyPair] {
        currencyPairs.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var totalValue: Double {
        currencyPairs.reduce(0) { $0 + $1.currentPrice }
    }
    
    var totalChange24h: Double {
        currencyPairs.reduce(0) { $0 + $1.priceChange24h }
    }
    
    var averageChangePercent24h: Double {
        guard !currencyPairs.isEmpty else { return 0 }
        let totalPercent = currencyPairs.reduce(0) { $0 + $1.priceChangePercent24h }
        return totalPercent / Double(currencyPairs.count)
    }
    
    func addCurrencyPair(_ pair: CurrencyPair) {
        pair.sortOrder = currencyPairs.count
        currencyPairs.append(pair)
        lastModified = Date()
    }
    
    func removeCurrencyPair(_ pair: CurrencyPair) {
        currencyPairs.removeAll { $0.id == pair.id }
        reorderPairs()
        lastModified = Date()
    }
    
    func movePair(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < currencyPairs.count,
              destinationIndex >= 0, destinationIndex <= currencyPairs.count else {
            return
        }
        
        let pair = currencyPairs.remove(at: sourceIndex)
        currencyPairs.insert(pair, at: destinationIndex)
        reorderPairs()
        lastModified = Date()
    }
    
    private func reorderPairs() {
        for (index, pair) in currencyPairs.enumerated() {
            pair.sortOrder = index
        }
    }
}