//
//  NSError+Extensions.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension NSError {
   static var networkUnreachableError: NSError {
      return NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [:])
   }

   static var networkTimeoutError: NSError {
      return NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [:])
   }

   public var isNetworkUnreachableError: Bool {
      return isNetworkError && code == NSURLErrorNotConnectedToInternet
   }

   public var isNetworkTimeoutError: Bool {
      return isNetworkError && code == NSURLErrorTimedOut
   }

   public var isNetworkError: Bool {
      return domain == NSURLErrorDomain
   }

   static func with(_ message: String) -> NSError {
      let error = NSError(domain: Bundle.main.bundleIdentifier ?? "com.Pointwelve",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: message])
      return error
   }
}
