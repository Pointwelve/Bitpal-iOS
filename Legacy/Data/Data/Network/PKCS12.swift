//
//  PKCS12.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

struct PKCS12 {
   private(set) var label: String?
   private(set) var keyID: Data?
   private(set) var trust: SecTrust?
   private(set) var certChain: [SecTrust]?
   private(set) var identity: SecIdentity?

   private(set) var securityError: OSStatus

   init(data: Data, password: String) {
      // self.securityError = errSecSuccess

      var items: CFArray?
      let certOptions: NSDictionary = [kSecImportExportPassphrase as NSString: password as NSString]

      // import certificate to read its entries
      securityError = SecPKCS12Import(data as NSData, certOptions, &items)

      if securityError == errSecSuccess {
         let certItems = (items! as Array)
         let dict = certItems.first! as! [String: Any]

         label = dict[kSecImportItemLabel as String] as? String
         keyID = dict[kSecImportItemKeyID as String] as? Data
         trust = dict[kSecImportItemTrust as String] as! SecTrust?
         certChain = dict[kSecImportItemCertChain as String] as? [SecTrust]
         identity = dict[kSecImportItemIdentity as String] as! SecIdentity?
      }
   }

   init(named: String, withPassword password: String) {
      self.init(data: NSData(contentsOfFile: Bundle.main.path(forResource: named, ofType: ".p12")!)! as Data, password: password)
   }

   var urlCredential: URLCredential {
      return URLCredential(identity: identity!,
                           certificates: certChain!,
                           persistence: .forSession)
   }
}
