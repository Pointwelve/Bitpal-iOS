//
//  Portfolio.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftData
import Foundation

@Model
final class Portfolio: Codable {
    var id: String = UUID().uuidString
    var name: String
    var totalValue: Double = 0.0
    var totalCost: Double = 0.0
    var totalProfitLoss: Double = 0.0
    var totalProfitLossPercent: Double = 0.0
    var holdings: [Holding] = []
    var transactions: [Transaction] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastModified: Date = Date()
    var isDeleted: Bool = false
    var isDefault: Bool = false
    
    init(name: String, isDefault: Bool = false) {
        self.name = name
        self.isDefault = isDefault
    }
    
    var totalProfitLossFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalProfitLoss)) ?? "$0.00"
    }
    
    var totalValueFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0.00"
    }
    
    var isPositivePerformance: Bool {
        return totalProfitLoss >= 0
    }
    
    func updateCalculations() {
        totalValue = holdings.reduce(0) { $0 + $1.currentValue }
        totalCost = holdings.reduce(0) { $0 + $1.totalCost }
        totalProfitLoss = totalValue - totalCost
        totalProfitLossPercent = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0
        updatedAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.totalValue = try container.decode(Double.self, forKey: .totalValue)
        self.totalCost = try container.decode(Double.self, forKey: .totalCost)
        self.totalProfitLoss = try container.decode(Double.self, forKey: .totalProfitLoss)
        self.totalProfitLossPercent = try container.decode(Double.self, forKey: .totalProfitLossPercent)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
        self.holdings = []
        self.transactions = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(totalValue, forKey: .totalValue)
        try container.encode(totalCost, forKey: .totalCost)
        try container.encode(totalProfitLoss, forKey: .totalProfitLoss)
        try container.encode(totalProfitLossPercent, forKey: .totalProfitLossPercent)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(isDefault, forKey: .isDefault)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, totalValue, totalCost, totalProfitLoss, totalProfitLossPercent
        case createdAt, updatedAt, lastModified, isDeleted, isDefault
    }
    
}

@Model
final class Holding: Codable {
    var id: String = UUID().uuidString
    var portfolio: Portfolio?
    var currency: Currency?
    var quantity: Double
    var averageCost: Double
    var totalCost: Double
    var currentPrice: Double = 0.0
    var currentValue: Double = 0.0
    var profitLoss: Double = 0.0
    var profitLossPercent: Double = 0.0
    var lastUpdated: Date = Date()
    var lastModified: Date = Date()
    var isDeleted: Bool = false
    var notes: String = ""
    
    init(currency: Currency, quantity: Double, averageCost: Double, portfolio: Portfolio? = nil) {
        self.currency = currency
        self.quantity = quantity
        self.averageCost = averageCost
        self.totalCost = quantity * averageCost
        self.portfolio = portfolio
        updateCalculations()
    }
    
    var displayName: String {
        return currency?.name ?? "Unknown"
    }
    
    var symbol: String {
        return currency?.symbol ?? ""
    }
    
    var profitLossFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: profitLoss)) ?? "$0.00"
    }
    
    var currentValueFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: currentValue)) ?? "$0.00"
    }
    
    var quantityFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: quantity)) ?? "0"
    }
    
    func updatePrice(_ newPrice: Double) {
        currentPrice = newPrice
        updateCalculations()
    }
    
    func updateCalculations() {
        currentValue = quantity * currentPrice
        profitLoss = currentValue - totalCost
        profitLossPercent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0
        lastUpdated = Date()
    }
    
    func addTransaction(_ transaction: Transaction) {
        portfolio?.transactions.append(transaction)
        
        switch transaction.type {
        case .buy:
            let newQuantity = quantity + transaction.quantity
            let newTotalCost = totalCost + (transaction.quantity * transaction.price)
            averageCost = newTotalCost / newQuantity
            quantity = newQuantity
            totalCost = newTotalCost
            
        case .sell:
            quantity -= transaction.quantity
            totalCost = quantity * averageCost
            
        case .transfer:
            if transaction.isIncoming {
                quantity += transaction.quantity
            } else {
                quantity -= transaction.quantity
            }
        }
        
        updateCalculations()
        portfolio?.updateCalculations()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.quantity = try container.decode(Double.self, forKey: .quantity)
        self.averageCost = try container.decode(Double.self, forKey: .averageCost)
        self.totalCost = try container.decode(Double.self, forKey: .totalCost)
        self.currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        self.currentValue = try container.decode(Double.self, forKey: .currentValue)
        self.profitLoss = try container.decode(Double.self, forKey: .profitLoss)
        self.profitLossPercent = try container.decode(Double.self, forKey: .profitLossPercent)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.portfolio = nil
        self.currency = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(averageCost, forKey: .averageCost)
        try container.encode(totalCost, forKey: .totalCost)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(currentValue, forKey: .currentValue)
        try container.encode(profitLoss, forKey: .profitLoss)
        try container.encode(profitLossPercent, forKey: .profitLossPercent)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(notes, forKey: .notes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, quantity, averageCost, totalCost, currentPrice, currentValue
        case profitLoss, profitLossPercent, lastUpdated, lastModified, isDeleted, notes
    }
    
}

@Model
final class Transaction: Codable {
    var id: String = UUID().uuidString
    var portfolio: Portfolio?
    var currency: Currency?
    var type: TransactionType
    var quantity: Double
    var price: Double
    var totalAmount: Double
    var fee: Double = 0.0
    var exchange: String = ""
    var notes: String = ""
    var timestamp: Date = Date()
    var lastModified: Date = Date()
    var isDeleted: Bool = false
    var isIncoming: Bool = false
    var txHash: String = ""
    
    init(
        currency: Currency,
        type: TransactionType,
        quantity: Double,
        price: Double,
        fee: Double = 0.0,
        exchange: String = "",
        notes: String = "",
        portfolio: Portfolio? = nil
    ) {
        self.currency = currency
        self.type = type
        self.quantity = quantity
        self.price = price
        self.totalAmount = quantity * price
        self.fee = fee
        self.exchange = exchange
        self.notes = notes
        self.portfolio = portfolio
    }
    
    var displayName: String {
        return currency?.name ?? "Unknown"
    }
    
    var symbol: String {
        return currency?.symbol ?? ""
    }
    
    var totalAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
    }
    
    var quantityFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: quantity)) ?? "0"
    }
    
    var priceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
    
    var typeDisplayName: String {
        switch type {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .transfer: return isIncoming ? "Receive" : "Send"
        }
    }
    
    var typeColor: String {
        switch type {
        case .buy: return "green"
        case .sell: return "red"
        case .transfer: return "blue"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.quantity = try container.decode(Double.self, forKey: .quantity)
        self.price = try container.decode(Double.self, forKey: .price)
        self.totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        self.fee = try container.decode(Double.self, forKey: .fee)
        self.exchange = try container.decode(String.self, forKey: .exchange)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
        self.txHash = try container.decode(String.self, forKey: .txHash)
        self.portfolio = nil
        self.currency = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(price, forKey: .price)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(fee, forKey: .fee)
        try container.encode(exchange, forKey: .exchange)
        try container.encode(notes, forKey: .notes)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(isIncoming, forKey: .isIncoming)
        try container.encode(txHash, forKey: .txHash)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, quantity, price, totalAmount, fee, exchange, notes
        case timestamp, lastModified, isDeleted, isIncoming, txHash
    }
    
}

enum TransactionType: String, CaseIterable, Codable {
    case buy = "buy"
    case sell = "sell"
    case transfer = "transfer"
    
    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .transfer: return "Transfer"
        }
    }
    
    var systemImage: String {
        switch self {
        case .buy: return "plus.circle.fill"
        case .sell: return "minus.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}