//
//  Configuration.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct Configuration: Equatable, DomainType {
   /// Root path for all server communication.
   public let apiHost: String

   /// Root path for all lambda functions.
   public let functionsHost: String

   /// Root path for socket server communication.
   public let socketHost: String

   /// Data of the ssl certificate for pinning purpose.
   public let sslCertificateData: Data?

   /// Company name
   public let companyName: String

   /// API Key
   public let apiKey: String

   /// Terms and Conditions
   public let termsAndConditions: String

   /// - Parameters:
   ///   - apiHost: Root path for all server communication.
   ///   - functionsHost: Root path for all lambda functions.
   ///   - socketHost: Root path for socket server communication.
   ///   - sslCertificateData: Data of the ssl certificate.
   ///   - currencyPairs: Currency Pairs raw data.
   ///   - companyName: Company name string.
   ///   - termsAndConditions: Terms and Conditions string.
   public init(apiHost: String,
               functionsHost: String,
               socketHost: String,
               sslCertificateData: Data? = nil,
               companyName: String,
               apiKey: String,
               termsAndConditions: String) {
      self.apiHost = apiHost
      self.functionsHost = functionsHost
      self.socketHost = socketHost
      self.sslCertificateData = sslCertificateData
      self.apiKey = apiKey
      self.companyName = companyName
      self.termsAndConditions = termsAndConditions
   }
}
