//
//  DataSyncService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftData
import Foundation
import Combine
import Observation

@MainActor
@Observable
final class DataSyncService: ReactiveService {
    static let shared = DataSyncService()
    
    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncTime: Date?
    private(set) var pendingChanges: Int = 0
    private(set) var syncProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    private let apiClient = APIClient.shared
    private let networkManager = ReactiveNetworkManager.shared
    private var syncTimer: Timer?
    private var conflictResolutionStrategy: ConflictResolutionStrategy = .serverWins
    
    private var syncQueue: [SyncOperation] = []
    private let operationQueue = OperationQueue()
    
    override init() {
        super.init()
        setupSyncTimer()
        setupNetworkMonitoring()
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    
    func setConflictResolutionStrategy(_ strategy: ConflictResolutionStrategy) {
        conflictResolutionStrategy = strategy
    }
    
    // MARK: - Public API
    
    func startAutoSync() {
        setupSyncTimer()
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func forceSyncAll() async {
        await performFullSync()
    }
    
    func syncEntity<T: SyncableEntity>(_ entityType: T.Type) async throws {
        guard networkManager.isConnected else {
            throw SyncError.noConnection
        }
        
        await performEntitySync(entityType)
    }
    
    func queueLocalChange<T>(_ entity: T, operation: SyncOperation.OperationType) where T: SyncableEntity {
        let syncOp = SyncOperation(
            id: UUID().uuidString,
            entityType: String(describing: T.self),
            entityId: entity.syncId,
            operationType: operation,
            timestamp: Date(),
            data: try? JSONEncoder().encode(entity)
        )
        
        syncQueue.append(syncOp)
        pendingChanges = syncQueue.count
        
        Task {
            await scheduleSync()
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performIncrementalSync()
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkManager.connectivityPublisher
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        await self?.performIncrementalSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func scheduleSync() async {
        guard syncStatus == .idle && networkManager.isConnected else { return }
        
        await performIncrementalSync()
    }
    
    private func performFullSync() async {
        guard networkManager.isConnected else {
            sendError(SyncError.noConnection)
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        setProcessing(true)
        
        await syncAllEntities()
        await processPendingChanges()
        
        syncStatus = .completed
        lastSyncTime = Date()
        syncProgress = 1.0
        
        setProcessing(false)
    }
    
    private func performIncrementalSync() async {
        guard networkManager.isConnected && !syncQueue.isEmpty else { return }
        
        syncStatus = .syncing
        setProcessing(true)
        
        await processPendingChanges()
        syncStatus = .completed
        lastSyncTime = Date()
        
        setProcessing(false)
    }
    
    private func syncAllEntities() async {
        let entityTypes: [any SyncableEntity.Type] = [
            Currency.self,
            Exchange.self,
            CurrencyPair.self,
            Alert.self,
            Portfolio.self,
            Holding.self,
            Transaction.self,
            UserPreferences.self
        ]
        
        let totalSteps = entityTypes.count
        var completedSteps = 0
        
        for entityType in entityTypes {
            await performEntitySync(entityType)
            completedSteps += 1
            syncProgress = Double(completedSteps) / Double(totalSteps)
        }
    }
    
    private func performEntitySync<T: SyncableEntity>(_ entityType: T.Type) async {
        guard let context = modelContext else { return }
        
        do {
            let localEntities = try await fetchLocalEntities(entityType)
            let serverEntities = try await fetchServerEntities(entityType)
            
            let conflicts = await detectConflicts(local: localEntities, server: serverEntities)
            let resolvedEntities = await resolveConflicts(conflicts)
            
            await applyResolvedChanges(resolvedEntities, to: context)
            
        } catch {
            print("Failed to sync \(entityType): \(error)")
        }
    }
    
    private func fetchLocalEntities<T>(_ entityType: T.Type) async throws -> [T] where T: SyncableEntity {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }
    
    private func fetchServerEntities<T>(_ entityType: T.Type) async throws -> [T] where T: SyncableEntity {
        let endpoint = CryptoAPIEndpoint.sync(entityType: String(describing: entityType))
        let response: SyncResponse<T> = try await apiClient.request(endpoint)
        return response.entities
    }
    
    private func detectConflicts<T>(local: [T], server: [T]) async -> [ConflictData<T>] where T: SyncableEntity {
        var conflicts: [ConflictData<T>] = []
        
        let localDict = Dictionary(uniqueKeysWithValues: local.map { ($0.syncId, $0) })
        let serverDict = Dictionary(uniqueKeysWithValues: server.map { ($0.syncId, $0) })
        
        for (id, localEntity) in localDict {
            if let serverEntity = serverDict[id] {
                if localEntity.lastModified != serverEntity.lastModified {
                    conflicts.append(ConflictData(
                        id: id,
                        local: localEntity,
                        server: serverEntity,
                        type: .modified
                    ))
                }
            } else {
                conflicts.append(ConflictData(
                    id: id,
                    local: localEntity,
                    server: nil,
                    type: .localOnly
                ))
            }
        }
        
        for (id, serverEntity) in serverDict {
            if localDict[id] == nil {
                conflicts.append(ConflictData(
                    id: id,
                    local: nil,
                    server: serverEntity,
                    type: .serverOnly
                ))
            }
        }
        
        return conflicts
    }
    
    private func resolveConflicts<T: SyncableEntity>(_ conflicts: [ConflictData<T>]) async -> [T] {
        var resolvedEntities: [T] = []
        
        for conflict in conflicts {
            let resolved = await resolveConflict(conflict)
            if let entity = resolved {
                resolvedEntities.append(entity)
            }
        }
        
        return resolvedEntities
    }
    
    private func resolveConflict<T: SyncableEntity>(_ conflict: ConflictData<T>) async -> T? {
        switch conflict.type {
        case .modified:
            return await resolveModificationConflict(conflict)
        case .localOnly:
            return conflict.local
        case .serverOnly:
            return conflict.server
        }
    }
    
    private func resolveModificationConflict<T: SyncableEntity>(_ conflict: ConflictData<T>) async -> T? {
        guard let local = conflict.local, let server = conflict.server else { return nil }
        
        switch conflictResolutionStrategy {
        case .serverWins:
            return server
        case .clientWins:
            return local
        case .newestWins:
            return local.lastModified > server.lastModified ? local : server
        case .manual:
            return await presentConflictResolutionUI(local: local, server: server)
        }
    }
    
    private func presentConflictResolutionUI<T: SyncableEntity>(local: T, server: T) async -> T? {
        return server
    }
    
    private func applyResolvedChanges<T: SyncableEntity>(_ entities: [T], to context: ModelContext) async {
        for entity in entities {
            let syncId = entity.syncId
            let predicate = #Predicate<T> { $0.syncId == syncId }
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let existingEntity = try? context.fetch(descriptor).first
            
            if let existing = existingEntity {
                existing.updateFrom(entity)
            } else {
                context.insert(entity)
            }
        }
        
        try? context.save()
    }
    
    private func processPendingChanges() async {
        guard !syncQueue.isEmpty else { return }
        
        let operations = Array(syncQueue)
        syncQueue.removeAll()
        pendingChanges = 0
        
        for operation in operations {
            await processOperation(operation)
        }
    }
    
    private func processOperation(_ operation: SyncOperation) async {
        do {
            let endpoint = CryptoAPIEndpoint.syncOperation(operation)
            let _: SyncOperationResponse = try await apiClient.request(endpoint)
            
        } catch {
            syncQueue.append(operation)
            pendingChanges = syncQueue.count
            print("Failed to process operation \(operation.id): \(error)")
        }
    }
}

// MARK: - Supporting Types

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed
}

enum ConflictResolutionStrategy {
    case serverWins
    case clientWins
    case newestWins
    case manual
}

enum SyncError: LocalizedError {
    case noConnection
    case syncInProgress
    case conflictResolutionRequired
    case serverError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection for sync"
        case .syncInProgress:
            return "Sync already in progress"
        case .conflictResolutionRequired:
            return "Manual conflict resolution required"
        case .serverError(let error):
            return "Server sync error: \(error.localizedDescription)"
        }
    }
}

struct ConflictData<T: SyncableEntity> {
    let id: String
    let local: T?
    let server: T?
    let type: ConflictType
    
    enum ConflictType {
        case modified
        case localOnly
        case serverOnly
    }
}

struct SyncOperation: Codable {
    let id: String
    let entityType: String
    let entityId: String
    let operationType: OperationType
    let timestamp: Date
    let data: Data?
    
    enum OperationType: String, Codable {
        case create
        case update
        case delete
    }
}

struct SyncResponse<T: SyncableEntity>: Codable where T: Codable {
    let entities: [T]
    let timestamp: Date
    let hasMore: Bool
}

struct SyncOperationResponse: Codable {
    let success: Bool
    let message: String?
    let timestamp: Date
}

// MARK: - Syncable Entity Protocol

protocol SyncableEntity: PersistentModel, Codable {
    var syncId: String { get }
    var lastModified: Date { get set }
    
    func updateFrom(_ other: Self)
}

// MARK: - Extensions

extension Currency: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Currency) {
        self.name = other.name
        self.symbol = other.symbol
        self.displaySymbol = other.displaySymbol
        self.lastModified = other.lastModified
    }
}

extension Exchange: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Exchange) {
        self.name = other.name
        self.displayName = other.displayName
        self.lastModified = other.lastModified
    }
}

extension CurrencyPair: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: CurrencyPair) {
        self.currentPrice = other.currentPrice
        self.priceChange24h = other.priceChange24h
        self.priceChangePercent24h = other.priceChangePercent24h
        self.high24h = other.high24h
        self.low24h = other.low24h
        self.volume24h = other.volume24h
        self.marketCap = other.marketCap
        self.lastModified = other.lastModified
    }
}

extension Alert: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Alert) {
        self.comparison = other.comparison
        self.targetPrice = other.targetPrice
        self.isEnabled = other.isEnabled
        self.message = other.message
        self.lastModified = other.lastModified
    }
}

extension Portfolio: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Portfolio) {
        self.name = other.name
        self.isDefault = other.isDefault
        self.lastModified = other.lastModified
    }
}

extension Holding: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Holding) {
        self.quantity = other.quantity
        self.averageCost = other.averageCost
        self.totalCost = other.totalCost
        self.notes = other.notes
        self.lastModified = other.lastModified
    }
}

extension Transaction: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: Transaction) {
        self.quantity = other.quantity
        self.price = other.price
        self.totalAmount = other.totalAmount
        self.fee = other.fee
        self.exchange = other.exchange
        self.notes = other.notes
        self.txHash = other.txHash
        self.lastModified = other.lastModified
    }
}

extension UserPreferences: SyncableEntity {
    var syncId: String { id }
    
    func updateFrom(_ other: UserPreferences) {
        self.theme = other.theme
        self.currency = other.currency
        self.notificationsEnabled = other.notificationsEnabled
        self.priceAlertsEnabled = other.priceAlertsEnabled
        self.newsAlertsEnabled = other.newsAlertsEnabled
        self.biometricAuthEnabled = other.biometricAuthEnabled
        self.defaultChartPeriod = other.defaultChartPeriod
        self.refreshIntervalSeconds = other.refreshIntervalSeconds
        self.lastModified = other.lastModified
    }
}