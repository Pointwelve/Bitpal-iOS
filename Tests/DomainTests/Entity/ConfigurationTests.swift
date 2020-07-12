//
//  ConfigurationTests.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class ConfigurationTests: XCTestCase {
   func testConfigurationEquality() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")
      XCTAssertEqual(a, b)
   }

   func testConfigurationInequalityOnApiHost() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")
      let b = Configuration(apiHost: "foobar",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      XCTAssertNotEqual(a, b)
   }

   func testConfigurationInequalityOnCertificateData() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "data"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      XCTAssertNotEqual(a, b)
   }

   func testConfigurationInequalityOnSocketHost() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test2",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      XCTAssertNotEqual(a, b)
   }

   func testConfigurationInequalityOnCompanyName() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test2",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "zzz",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      XCTAssertNotEqual(a, b)
   }

   func testConfigurationInequalityOnTerms() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test2",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "blablabla")

      XCTAssertNotEqual(a, b)
   }

   func testConfigurationInequalityOnApiKey() {
      let a = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "test",
                            termsAndConditions: "foobar")

      let b = Configuration(apiHost: "test",
                            functionsHost: "test",
                            socketHost: "test2",
                            sslCertificateData: Data(base64Encoded: "test"),
                            
                            companyName: "testName",
                            apiKey: "testZ",
                            termsAndConditions: "foobar")

      XCTAssertNotEqual(a, b)
   }
}
