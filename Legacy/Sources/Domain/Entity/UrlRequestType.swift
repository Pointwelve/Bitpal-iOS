//
//  UrlRequestType.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum UrlRequestType {
   case api(authorizationHeader: String?, router: APIRouter)

   internal func url(for host: String, language: Language) -> URL {
      switch self {
      case let .api(_, route):
         let hostComponents = host.components(separatedBy: ":")

         // Construct components
         var components = URLComponents()
         components.scheme = "https"

         // TODO: remove when production URL is provided as port would/might no longer make sense
         if hostComponents.count > 1 { // If it has more than one component, assume the second component as port
            components.host = hostComponents[0]
            components.port = Int(hostComponents[1])
         } else {
            components.host = host
         }

         // Append relative path
         components.path = "\(route.relativePath)"

         if host == "localhost:5000" {
            components.scheme = "http"
            components.path = "/bitpal-dev/us-central1\(route.relativePath)"
         }

         // Set query items
         components.queryItems = route.query

         return components.url!
      }
   }

   public func request(for host: String, language: Language) -> URLRequest {
      let url = self.url(for: host, language: language)
      var request = URLRequest(url: url)
      request.adding(headerFields: [.acceptLanguage(language)])
      switch self {
      case let .api(authorizationHeader, route):
         // Authorization header is required for API calls
         request.httpMethod = route.method.rawValue
         if let authorizationHeader = authorizationHeader {
            request.adding(headerField: .authorization(authorizationHeader))
         }
      }
      return request
   }
}
