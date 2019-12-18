//
//  ConfigurationData.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// The `ConfigurationData` is DataType that is used in the data layer.
struct ConfigurationData: DataType {
   /// Root path for all server communication.
   let apiHost: String

   /// Root path for socket functions host.
   let functionsHost: String

   /// Root path for socket server communication.
   let socketHost: String

   /// Data of the ssl certificate.
   let sslCertificateData: Data?

   /// Company name
   let companyName: String

   /// Terms and Conditions
   let termsAndConditions: String
}
