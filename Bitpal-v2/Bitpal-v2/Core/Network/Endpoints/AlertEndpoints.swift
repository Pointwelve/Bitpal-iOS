//
//  AlertEndpoints.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

enum AlertEndpoints: APIEndpoint {
    case alerts
    case alert(String)
    case createAlert(APICreateAlertRequest)
    case updateAlert(String, APIUpdateAlertRequest)
    case deleteAlert(String)
    case alertHistory(String)
    
    var path: String {
        switch self {
        case .alerts:
            return "/v1/alerts"
        case .alert(let id):
            return "/v1/alerts/\(id)"
        case .createAlert:
            return "/v1/alerts"
        case .updateAlert(let id, _):
            return "/v1/alerts/\(id)"
        case .deleteAlert(let id):
            return "/v1/alerts/\(id)"
        case .alertHistory(let id):
            return "/v1/alerts/\(id)/history"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .alerts, .alert, .alertHistory:
            return .GET
        case .createAlert:
            return .POST
        case .updateAlert:
            return .PUT
        case .deleteAlert:
            return .DELETE
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil // Alert endpoints don't use query parameters
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: [String: Any]? {
        let encoder = JSONEncoder()
        
        switch self {
        case .createAlert(let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateAlert(_, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        default:
            break
        }
        return nil
    }
    
    func url(baseURL: URL, apiKey: String) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        
        var allQueryItems = queryItems ?? []
        
        if !apiKey.isEmpty {
            allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        
        components?.queryItems = allQueryItems.isEmpty ? nil : allQueryItems
        return components?.url
    }
}