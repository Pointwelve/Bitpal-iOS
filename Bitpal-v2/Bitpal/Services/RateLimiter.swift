//
//  RateLimiter.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation
import OSLog

/// Actor-based rate limiter to enforce minimum intervals between API requests
/// Per Constitution Principle I: Respect CoinGecko free tier rate limits (50 calls/min)
actor RateLimiter {
    // MARK: - Properties

    /// Minimum time interval between requests (1.2 seconds = 50 requests/min)
    private let minimumInterval: TimeInterval = 1.2

    /// Timestamp of last request completion
    private var lastRequestTime: Date?

    // MARK: - Public Methods

    /// Wait until rate limit allows next request
    /// Per Constitution: 1.2s minimum interval for CoinGecko free tier
    func waitForNextRequest() async {
        guard let lastTime = lastRequestTime else {
            // First request - no wait needed
            lastRequestTime = Date()
            Logger.api.debug("RateLimiter: First request, no delay")
            return
        }

        let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
        let remainingWait = minimumInterval - timeSinceLastRequest

        if remainingWait > 0 {
            Logger.api.debug("RateLimiter: Waiting \(remainingWait, privacy: .public)s before next request")
            try? await Task.sleep(for: .seconds(remainingWait))
        }

        lastRequestTime = Date()
        Logger.api.debug("RateLimiter: Request allowed")
    }

    /// Reset rate limiter (useful for testing)
    func reset() {
        lastRequestTime = nil
        Logger.api.debug("RateLimiter: Reset")
    }
}
