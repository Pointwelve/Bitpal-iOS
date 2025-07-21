//
//  NetworkError.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case httpError(statusCode: Int)
    case timeout
    case noInternetConnection
    case serverUnavailable
    case unauthorized
    case rateLimitExceeded
    case apiKeyInvalid
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .timeout:
            return "Request timed out"
        case .noInternetConnection:
            return "No internet connection"
        case .serverUnavailable:
            return "Server unavailable"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .apiKeyInvalid:
            return "Invalid API key"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .httpError(let statusCode):
            switch statusCode {
            case 400:
                return "Bad request - check your parameters"
            case 401:
                return "Unauthorized - check your API key"
            case 403:
                return "Forbidden - access denied"
            case 404:
                return "Not found - resource doesn't exist"
            case 429:
                return "Too many requests - try again later"
            case 500...599:
                return "Server error - try again later"
            default:
                return "HTTP error occurred"
            }
        case .timeout:
            return "The request took too long to complete"
        case .noInternetConnection:
            return "Check your internet connection"
        default:
            return nil
        }
    }
}