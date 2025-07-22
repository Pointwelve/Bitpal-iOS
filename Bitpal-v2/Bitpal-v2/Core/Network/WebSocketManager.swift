//
//  WebSocketManager.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Combine
import Observation

@MainActor
@Observable
final class WebSocketManager {
    
    enum MessageType: Int, CaseIterable {
        case sessionWelcome = 4000
        case streamerError = 4001
        case rateLimitError = 4002
        case subscriptionError = 4003
        case subscriptionValidationError = 4004
        case subscriptionAccepted = 4005
        case subscriptionRejected = 4006
        case subscriptionAddComplete = 4007
        case subscriptionRemoveComplete = 4008
        case subscriptionRemoveAllComplete = 4009
        case subscriptionWarning = 4010
        case authenticationWarning = 4011
        case messageValidationError = 4012
        case heartbeat = 4013
        
        var description: String {
            switch self {
            case .sessionWelcome:
                return "Session Welcome - Connection established"
            case .streamerError:
                return "Streamer Error - Non-JSON or malformed message"
            case .rateLimitError:
                return "Rate Limit Error - Rate limits exceeded"
            case .subscriptionError:
                return "Subscription Error - General subscription processing error"
            case .subscriptionValidationError:
                return "Subscription Validation Error - Invalid parameters"
            case .subscriptionAccepted:
                return "Subscription Accepted - Successfully processed"
            case .subscriptionRejected:
                return "Subscription Rejected - Cannot be processed"
            case .subscriptionAddComplete:
                return "Subscription Add Complete - All subscriptions added"
            case .subscriptionRemoveComplete:
                return "Subscription Remove Complete - Successfully removed"
            case .subscriptionRemoveAllComplete:
                return "Subscription Remove All Complete - All subscriptions removed"
            case .subscriptionWarning:
                return "Subscription Warning - Inactive instruments"
            case .authenticationWarning:
                return "Authentication Warning - Fallback to IP rate limits"
            case .messageValidationError:
                return "Message Validation Error - Non-conforming message"
            case .heartbeat:
                return "Heartbeat - Connection alive check"
            }
        }
        
        var isError: Bool {
            switch self {
            case .streamerError, .rateLimitError, .subscriptionError, .subscriptionValidationError, .subscriptionRejected, .messageValidationError:
                return true
            default:
                return false
            }
        }
        
        var isWarning: Bool {
            switch self {
            case .subscriptionWarning, .authenticationWarning:
                return true
            default:
                return false
            }
        }
    }
    enum ConnectionState: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed(String)
    }
    
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var lastError: Error?
    private(set) var lastMessageType: MessageType?
    private(set) var isAuthenticated: Bool = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let session = URLSession.shared
    private var subscriptions = Set<String>()
    private var apiKey: String = ""
    
    // Reconnection delays (exponential backoff)
    private let reconnectDelays: [TimeInterval] = [1, 2, 4, 8, 16]
    
    var onPriceUpdate: ((StreamPrice) -> Void)?
    var onMessageReceived: ((MessageType, [String: Any]) -> Void)?
    var onError: ((MessageType, String) -> Void)?
    var onWarning: ((MessageType, String) -> Void)?
    
    func setAPIKey(_ key: String) {
        apiKey = key
    }
    
    func connect() async {
        switch connectionState {
        case .disconnected, .failed(_):
            break
        default:
            return
        }
        
        connectionState = .connecting
        reconnectAttempts = 0
        
        await performConnection()
    }
    
    private func performConnection() async {
        guard !apiKey.isEmpty else {
            connectionState = .failed("API key is invalid or empty")
            return
        }
        
        let urlString = "wss://data-streamer.coindesk.com/?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            connectionState = .failed("Invalid WebSocket URL")
            return
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Note: connectionState will be set to .connected when we receive sessionWelcome (4000)
        startPingTimer()
        
        // Re-subscribe to previous subscriptions
        for subscription in subscriptions {
            await subscribe(to: subscription)
        }
        
        // Start receiving messages
        await receiveMessage()
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        isAuthenticated = false
        lastMessageType = nil
        subscriptions.removeAll()
        print("🔌 WebSocket disconnected")
    }
    
    func removeAllSubscriptions() async {
        guard connectionState == .connected else { return }
        
        let removeAllMessage: [String: Any] = [
            "action": "UNSUBSCRIBE_ALL"
        ]
        
        await sendMessage(removeAllMessage)
        subscriptions.removeAll()
    }
    
    func subscribe(to symbol: String) async {
        subscriptions.insert(symbol)
        
        guard connectionState == .connected else { 
            print("📡 WebSocket: Queued subscription for \(symbol) (not connected yet)")
            return 
        }
        
        // CoinDesk subscription format
        let subscribeMessage: [String: Any] = [
            "action": "SUBSCRIBE",
            "type": "index_cc_v1_latest_tick",
            "market": "cadli",
            "instruments": [symbol],
            "groups": ["VALUE", "CURRENT_HOUR"]
        ]
        
        await sendMessage(subscribeMessage)
        print("📡 WebSocket: Sent subscription for \(symbol)")
    }
    
    func unsubscribe(from symbol: String) async {
        subscriptions.remove(symbol)
        
        guard connectionState == .connected else { return }
        
        // CoinDesk unsubscription format
        let unsubscribeMessage: [String: Any] = [
            "action": "UNSUBSCRIBE",
            "type": "index_cc_v1_latest_tick",
            "market": "cadli",
            "instruments": [symbol],
            "groups": ["VALUE", "CURRENT_HOUR"]
        ]
        
        await sendMessage(unsubscribeMessage)
    }
    
    private func sendMessage(_ message: [String: Any]) async {
        guard let webSocketTask = webSocketTask else {
            onError?(.subscriptionError, "WebSocket task not available")
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let string = String(data: data, encoding: .utf8) ?? ""
            let websocketMessage = URLSessionWebSocketTask.Message.string(string)
            
            try await webSocketTask.send(websocketMessage)
            
            // Log outgoing messages for debugging
            if let action = message["action"] as? String {
                print("📤 WebSocket sent: \(action)")
                if let instruments = message["instruments"] as? [String] {
                    print("   Instruments: \(instruments.joined(separator: ", "))")
                }
            }
        } catch {
            lastError = error
            onError?(.streamerError, "Failed to send message: \(error.localizedDescription)")
            await handleConnectionError()
        }
    }
    
    private func receiveMessage() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let message = try await webSocketTask.receive()
            
            switch message {
            case .string(let text):
                await handleMessage(text)
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    await handleMessage(text)
                }
            @unknown default:
                break
            }
            
            // Continue receiving messages
            await receiveMessage()
            
        } catch {
            lastError = error
            await handleConnectionError()
        }
    }
    
    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        
        // Debug: Log ALL incoming WebSocket messages
        print("🔍 WebSocket RAW message: \(String(text.prefix(500)))")
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 WebSocket JSON keys: \(Array(json.keys).sorted())")
                if let type = json["TYPE"] as? String {
                    print("🔍 WebSocket TYPE: \(type)")
                }
                
                // CoinDesk uses TYPE field with string values like "4000", "4013"
                if let typeString = json["TYPE"] as? String,
                   let messageTypeRaw = Int(typeString),
                   let messageType = MessageType(rawValue: messageTypeRaw) {
                    
                    lastMessageType = messageType
                    await handleWebSocketMessage(messageType, json: json)
                    
                } else if let messageTypeRaw = json["message_type"] as? Int,
                          let messageType = MessageType(rawValue: messageTypeRaw) {
                    // Fallback for integer message_type field
                    lastMessageType = messageType
                    await handleWebSocketMessage(messageType, json: json)
                    
                } else if let typeString = json["TYPE"] as? String {
                    // Handle CoinDesk price data messages with TYPE values like "1101"
                    switch typeString {
                    case "1101": // CoinDesk price data
                        let streamPrice = try JSONDecoder().decode(StreamPrice.self, from: data)
                        onPriceUpdate?(streamPrice)
                        print("💰 Price update: \(streamPrice.instrument ?? "Unknown") = \(streamPrice.value ?? 0)")
                        
                    default:
                        // Log unrecognized TYPE values for debugging
                        print("🔄 WebSocket: Unknown TYPE value: \(typeString)")
                        print("   Keys: \(Array(json.keys).joined(separator: ", "))")
                        print("   Sample data: \(String(text.prefix(200)))...")
                    }
                    
                } else {
                    // Handle other CoinDesk price data messages (no TYPE field)
                    if json["instrument"] != nil || json["value"] != nil {
                        let streamPrice = try JSONDecoder().decode(StreamPrice.self, from: data)
                        onPriceUpdate?(streamPrice)
                    } else {
                        // Log truly unrecognized messages for debugging
                        print("🔄 WebSocket: Unrecognized message format")
                        print("   Keys: \(Array(json.keys).joined(separator: ", "))")
                        print("   Sample data: \(String(text.prefix(200)))...")
                    }
                }
            }
        } catch {
            print("❌ WebSocket parsing error: \(error)")
            print("   Raw message: \(String(text.prefix(500)))...")
            // Trigger message validation error callback
            onError?(.messageValidationError, "Failed to parse message: \(error.localizedDescription)")
        }
    }
    
    private func handleWebSocketMessage(_ messageType: MessageType, json: [String: Any]) async {
        // Notify listeners
        onMessageReceived?(messageType, json)
        
        // CoinDesk uses "MESSAGE" field, fallback to "message"
        let message = json["MESSAGE"] as? String ?? json["message"] as? String ?? ""
        let details = json["details"] as? String ?? ""
        
        switch messageType {
        case .sessionWelcome:
            print("✅ WebSocket: \(messageType.description)")
            isAuthenticated = true
            connectionState = .connected
            
            // Process queued subscriptions now that we're connected
            print("📡 WebSocket: Processing \(subscriptions.count) queued subscriptions")
            for subscription in subscriptions {
                await subscribe(to: subscription)
            }
            
        case .subscriptionAccepted:
            print("✅ WebSocket: \(messageType.description)")
            if let instruments = json["instruments"] as? [String] {
                print("   Subscribed to: \(instruments.joined(separator: ", "))")
            }
            
        case .subscriptionAddComplete:
            print("✅ WebSocket: \(messageType.description)")
            
        case .subscriptionRemoveComplete:
            print("✅ WebSocket: \(messageType.description)")
            
        case .subscriptionRemoveAllComplete:
            print("✅ WebSocket: \(messageType.description)")
            
        case .heartbeat:
            // Silent heartbeat handling
            break
            
        // Warning cases
        case .subscriptionWarning:
            print("⚠️ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Warning: \(message)")
            }
            onWarning?(messageType, message)
            
        case .authenticationWarning:
            print("⚠️ WebSocket: \(messageType.description)")
            isAuthenticated = false
            if !message.isEmpty {
                print("   Warning: \(message)")
            }
            onWarning?(messageType, message)
            
        // Error cases
        case .streamerError:
            print("❌ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Error: \(message)")
            }
            onError?(messageType, message)
            
        case .rateLimitError:
            print("❌ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Error: \(message)")
            }
            onError?(messageType, message)
            // Consider implementing rate limit backoff
            await handleRateLimitError()
            
        case .subscriptionError:
            print("❌ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Error: \(message)")
            }
            onError?(messageType, message)
            
        case .subscriptionValidationError:
            print("❌ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Error: \(message)")
            }
            if !details.isEmpty {
                print("   Details: \(details)")
            }
            onError?(messageType, "\(message) \(details)".trimmingCharacters(in: .whitespaces))
            
        case .subscriptionRejected:
            print("❌ WebSocket: \(messageType.description)")
            if let instruments = json["instruments"] as? [String] {
                print("   Rejected instruments: \(instruments.joined(separator: ", "))")
                // Remove rejected instruments from subscriptions
                for instrument in instruments {
                    subscriptions.remove(instrument)
                }
            }
            if !message.isEmpty {
                print("   Reason: \(message)")
            }
            onError?(messageType, message)
            
        case .messageValidationError:
            print("❌ WebSocket: \(messageType.description)")
            if !message.isEmpty {
                print("   Error: \(message)")
            }
            onError?(messageType, message)
        }
    }
    
    private func handleRateLimitError() async {
        // Implement exponential backoff for rate limiting
        let backoffDelay: TimeInterval = 30 // 30 seconds for rate limit
        print("🔄 Implementing rate limit backoff: \(backoffDelay)s")
        
        try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.sendPing()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() async {
        guard let webSocketTask = webSocketTask else { return }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            webSocketTask.sendPing { [weak self] error in
                if error != nil {
                    Task { @MainActor in
                        await self?.handleConnectionError()
                    }
                }
                continuation.resume()
            }
        }
    }
    
    private func handleConnectionError() async {
        connectionState = .reconnecting
        isAuthenticated = false
        stopPingTimer()
        
        // Don't reconnect if we've exceeded max attempts
        guard reconnectAttempts < maxReconnectAttempts else {
            let errorMessage = "Max reconnection attempts (\(maxReconnectAttempts)) exceeded"
            connectionState = .failed(errorMessage)
            onError?(.subscriptionError, errorMessage)
            return
        }
        
        let delay = reconnectDelays[min(reconnectAttempts, reconnectDelays.count - 1)]
        reconnectAttempts += 1
        
        print("🔄 WebSocket reconnecting in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.performConnection()
            }
        }
    }
    
    func getConnectionStatus() -> (state: ConnectionState, authenticated: Bool, lastMessage: MessageType?) {
        return (connectionState, isAuthenticated, lastMessageType)
    }
    
    func clearErrors() {
        lastError = nil
        lastMessageType = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

// StreamPrice is defined in Core/Models/StreamPrice.swift