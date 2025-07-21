//
//  URLSessionConfiguration+IgnoreHTTPCache.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
   /// Make session configuration with HTTP caching disabled.
   static func makeSessionConfigurationIgnoringHttpCache() -> URLSessionConfiguration {
      let configuration = URLSessionConfiguration.default
      // Disable local HTTP cache, we use our own cache that is limited to only X items
      configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
      return configuration
   }
}
