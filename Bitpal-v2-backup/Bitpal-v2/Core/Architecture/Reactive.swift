//
//  Reactive.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Combine
import Observation

// MARK: - Observable Stream

@MainActor
final class ObservableStream<T>: ObservableObject {
    @Published private(set) var value: T
    @Published private(set) var error: Error?
    @Published private(set) var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let subject = PassthroughSubject<T, Never>()
    
    init(initialValue: T) {
        self.value = initialValue
        
        subject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.value = newValue
                self?.error = nil
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func send(_ value: T) {
        subject.send(value)
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func setError(_ error: Error) {
        self.error = error
        self.isLoading = false
    }
    
    var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - Reactive Service Base

@MainActor
@Observable
class ReactiveService {
    public var cancellables = Set<AnyCancellable>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    
    private(set) var lastError: Error?
    private(set) var isProcessing = false
    
    init() {
        errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.lastError = error
                self?.isProcessing = false
            }
            .store(in: &cancellables)
    }
    
    deinit {
        Task { @MainActor in
            cancellables.removeAll()
            clearAllSubscriptions()
        }
    }
    
    private func clearAllSubscriptions() {
        errorSubject.send(completion: .finished)
    }
    
    func setProcessing(_ processing: Bool) {
        isProcessing = processing
        if processing {
            lastError = nil
        }
    }
    
    func sendError(_ error: Error) {
        errorSubject.send(error)
    }
    
    func clearError() {
        lastError = nil
    }
    
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}

// MARK: - Reactive Data Manager

@MainActor
final class ReactiveDataManager<T: Identifiable & Codable>: ReactiveService {
    @Published private(set) var items: [T] = []
    @Published private(set) var isLoading = false
    
    private let itemsSubject = CurrentValueSubject<[T], Never>([])
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    
    override init() {
        super.init()
        setupBindings()
    }
    
    deinit {
        itemsSubject.send(completion: .finished)
        loadingSubject.send(completion: .finished)
    }
    
    private func setupBindings() {
        itemsSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
        
        loadingSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
    
    func setItems(_ items: [T]) {
        itemsSubject.send(items)
    }
    
    func addItem(_ item: T) {
        var currentItems = itemsSubject.value
        currentItems.append(item)
        itemsSubject.send(currentItems)
    }
    
    func updateItem(_ item: T) {
        var currentItems = itemsSubject.value
        if let index = currentItems.firstIndex(where: { $0.id == item.id }) {
            currentItems[index] = item
            itemsSubject.send(currentItems)
        }
    }
    
    func removeItem(id: T.ID) {
        var currentItems = itemsSubject.value
        currentItems.removeAll { $0.id == id }
        itemsSubject.send(currentItems)
    }
    
    func setLoading(_ loading: Bool) {
        loadingSubject.send(loading)
        setProcessing(loading)
    }
    
    var itemsPublisher: AnyPublisher<[T], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    var loadingPublisher: AnyPublisher<Bool, Never> {
        loadingSubject.eraseToAnyPublisher()
    }
    
    func filter(_ predicate: @escaping (T) -> Bool) -> AnyPublisher<[T], Never> {
        itemsSubject
            .map { items in items.filter(predicate) }
            .eraseToAnyPublisher()
    }
    
    func map<U>(_ transform: @escaping (T) -> U) -> AnyPublisher<[U], Never> {
        itemsSubject
            .map { items in items.map(transform) }
            .eraseToAnyPublisher()
    }
    
    func sorted(by comparator: @escaping (T, T) -> Bool) -> AnyPublisher<[T], Never> {
        itemsSubject
            .map { items in items.sorted(by: comparator) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Reactive State Manager

@MainActor
final class ReactiveStateManager<State>: ReactiveService {
    @Published private(set) var state: State
    
    private let stateSubject: CurrentValueSubject<State, Never>
    
    init(initialState: State) {
        self.state = initialState
        self.stateSubject = CurrentValueSubject(initialState)
        super.init()
        setupBindings()
    }
    
    deinit {
        stateSubject.send(completion: .finished)
    }
    
    private func setupBindings() {
        stateSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    func setState(_ newState: State) {
        stateSubject.send(newState)
    }
    
    func updateState(_ transform: (State) -> State) {
        let newState = transform(stateSubject.value)
        stateSubject.send(newState)
    }
    
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}

// MARK: - Reactive Event Bus

@MainActor
final class ReactiveEventBus: ObservableObject {
    static let shared = ReactiveEventBus()
    
    private var subjects: [String: Any] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let accessQueue = DispatchQueue(label: "eventbus.access", attributes: .concurrent)
    
    private init() {}
    
    deinit {
        Task { @MainActor in
            clear()
            cancellables.removeAll()
        }
    }
    
    func publish<T>(_ event: T, to channel: String = String(describing: T.self)) {
        Task { @MainActor in
            if let subject = subjects[channel] as? PassthroughSubject<T, Never> {
                subject.send(event)
            } else {
                let newSubject = PassthroughSubject<T, Never>()
                subjects[channel] = newSubject
                newSubject.send(event)
            }
        }
    }
    
    func subscribe<T>(to eventType: T.Type, channel: String = String(describing: T.self)) -> AnyPublisher<T, Never> {
        if let subject = subjects[channel] as? PassthroughSubject<T, Never> {
            return subject.eraseToAnyPublisher()
        } else {
            let newSubject = PassthroughSubject<T, Never>()
            subjects[channel] = newSubject
            return newSubject.eraseToAnyPublisher()
        }
    }
    
    func clear(channel: String? = nil) {
        Task { @MainActor in
            if let channel = channel {
                if let subject = subjects.removeValue(forKey: channel) as? PassthroughSubject<Any, Never> {
                    subject.send(completion: .finished)
                }
            } else {
                subjects.values.forEach { subject in
                    if let passThroughSubject = subject as? PassthroughSubject<Any, Never> {
                        passThroughSubject.send(completion: .finished)
                    }
                }
                subjects.removeAll()
            }
        }
    }
}

// MARK: - Reactive Network Manager

@MainActor
final class ReactiveNetworkManager: ReactiveService {
    static let shared = ReactiveNetworkManager()
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let session = URLSession.shared
    private let reachabilitySubject = CurrentValueSubject<Bool, Never>(true)
    private let connectionTypeSubject = CurrentValueSubject<ConnectionType, Never>(.unknown)
    private var monitoringTimer: Timer?
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    override init() {
        super.init()
        setupBindings()
        startMonitoring()
    }
    
    deinit {
        monitoringTimer?.invalidate()
        reachabilitySubject.send(completion: .finished)
        connectionTypeSubject.send(completion: .finished)
    }
    
    private func setupBindings() {
        reachabilitySubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        connectionTypeSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionType)
    }
    
    private func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkConnectivity()
            }
        }
    }
    
    private func checkConnectivity() async {
        do {
            let url = URL(string: "https://www.google.com")!
            let (_, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let connected = httpResponse.statusCode == 200
                reachabilitySubject.send(connected)
            }
        } catch {
            reachabilitySubject.send(false)
        }
    }
    
    func request<T: Codable>(_ request: URLRequest, responseType: T.Type) -> AnyPublisher<T, Error> {
        guard isConnected else {
            return Fail(error: NetworkError.noInternetConnection)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    var connectivityPublisher: AnyPublisher<Bool, Never> {
        reachabilitySubject.eraseToAnyPublisher()
    }
    
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        connectionTypeSubject.eraseToAnyPublisher()
    }
}

// MARK: - Reactive Cache Manager

final class ReactiveCacheManager<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let expirationDate: Date
    }
    
    private var cache: [Key: CacheEntry] = [:]
    private let accessQueue = DispatchQueue(label: "cache-access", attributes: .concurrent)
    
    private var _cacheSize: Int = 0
    private var _hitRate: Double = 0.0
    private var totalRequests: Int = 0
    private var cacheHits: Int = 0
    
    var cacheSize: Int {
        accessQueue.sync { _cacheSize }
    }
    
    var hitRate: Double {
        accessQueue.sync { _hitRate }
    }
    
    func setValue(_ value: Value, forKey key: Key, expirationInterval: TimeInterval = 300) {
        accessQueue.async(flags: .barrier) { [weak self] in
            let expirationDate = Date().addingTimeInterval(expirationInterval)
            let entry = CacheEntry(value: value, expirationDate: expirationDate)
            self?.cache[key] = entry
            self?.updateCacheStats()
        }
    }
    
    func getValue(forKey key: Key) -> AnyPublisher<Value?, Never> {
        return Future { [weak self] promise in
            self?.accessQueue.async {
                self?.totalRequests += 1
                
                guard let entry = self?.cache[key] else {
                    self?.updateCacheStats()
                    promise(.success(nil))
                    return
                }
                
                if Date() > entry.expirationDate {
                    self?.cache.removeValue(forKey: key)
                    self?.updateCacheStats()
                    promise(.success(nil))
                    return
                }
                
                self?.cacheHits += 1
                self?.updateCacheStats()
                promise(.success(entry.value))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeValue(forKey key: Key) {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: key)
            DispatchQueue.main.async {
                self?.updateCacheStats()
            }
        }
    }
    
    func clearCache() {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
            self?._cacheSize = 0
            self?._hitRate = 0.0
            self?.totalRequests = 0
            self?.cacheHits = 0
        }
    }
    
    private func updateCacheStats() {
        _cacheSize = cache.count
        _hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    var cacheSizePublisher: AnyPublisher<Int, Never> {
        Just(cacheSize).eraseToAnyPublisher()
    }
    
    var hitRatePublisher: AnyPublisher<Double, Never> {
        Just(hitRate).eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

// MARK: - Reactive Extensions

extension Publisher {
    func withLatestFrom<Other: Publisher, Result>(
        _ other: Other,
        resultSelector: @escaping (Output, Other.Output) -> Result
    ) -> Publishers.WithLatestFrom<Self, Other, Result> {
        return Publishers.WithLatestFrom(upstream: self, other: other, resultSelector: resultSelector)
    }
}

extension Publishers {
    struct WithLatestFrom<Upstream: Publisher, Other: Publisher, Output>: Publisher {
        typealias Failure = Upstream.Failure
        
        let upstream: Upstream
        let other: Other
        let resultSelector: (Upstream.Output, Other.Output) -> Output
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = WithLatestFromSubscription(
                upstream: upstream,
                other: other,
                resultSelector: resultSelector,
                subscriber: subscriber
            )
            subscriber.receive(subscription: subscription)
        }
    }
}

private final class WithLatestFromSubscription<Upstream: Publisher, Other: Publisher, Output, S: Subscriber>: Subscription
where S.Input == Output, S.Failure == Upstream.Failure {
    
    private var subscriber: S?
    private var upstreamSubscription: Subscription?
    private var otherSubscription: Subscription?
    private var latestOtherValue: Other.Output?
    private let resultSelector: (Upstream.Output, Other.Output) -> Output
    
    init(upstream: Upstream, other: Other, resultSelector: @escaping (Upstream.Output, Other.Output) -> Output, subscriber: S) {
        self.resultSelector = resultSelector
        self.subscriber = subscriber
        
        upstream.sink(
            receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.subscriber?.receive(completion: .finished)
                case .failure(let error):
                    self?.subscriber?.receive(completion: .failure(error))
                }
            },
            receiveValue: { [weak self] upstreamValue in
                guard let self = self,
                      let latestOther = self.latestOtherValue else { return }
                
                let result = self.resultSelector(upstreamValue, latestOther)
                _ = self.subscriber?.receive(result)
            }
        ).store(in: &cancellables)
        
        other.sink(
            receiveCompletion: { _ in },
            receiveValue: { [weak self] otherValue in
                self?.latestOtherValue = otherValue
            }
        ).store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        cancellables.removeAll()
        subscriber = nil
    }
}

// MARK: - Async/Await Extensions

extension Publisher where Failure == Never {
    func singleOutput() async -> Output? {
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self
                .first()
                .sink { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
        }
    }
}

extension Publisher {
    func singleOutput() async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self
                .first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}