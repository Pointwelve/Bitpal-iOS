//
//  PKCS12Tests.swift
//  Data
//
//  Created by Alvin Choo on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import XCTest

class PKCS12Tests: XCTestCase {
   // swiftlint:disable line_length
   private let data = "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"

   func testPKCSInit() {
      let data = Data(base64Encoded: self.data)!

      let pkcs = PKCS12(data: data, password: "test")

      XCTAssertNotNil(pkcs.identity)
      XCTAssertNotNil(pkcs.certChain)
      XCTAssertNotNil(pkcs.trust)
      XCTAssertTrue(pkcs.certChain!.count == 2)

      let credential = pkcs.urlCredential

      XCTAssertNotNil(credential.identity)
      XCTAssertTrue(credential.certificates.count == 2)
      XCTAssertTrue(credential.persistence == .forSession)
   }
}
