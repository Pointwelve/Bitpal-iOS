//
//  ConfigurationTranformTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class ConfigurationTranformTests: XCTestCase {
   func testTranformingToConfigurationFromConfigurationData() {
      let expectedServerURL = "test.test"

      let configurationDataType = ConfigurationData(apiHost: expectedServerURL,
                                                    functionsHost: "www.func.com",
                                                    socketHost: "sockethost",
                                                    sslCertificateData: Data(),
                                                    companyName: "testName",
                                                    termsAndConditions: "foobar")

      let actualServerURL = configurationDataType.asDomain().apiHost
      XCTAssertEqual(expectedServerURL, actualServerURL)
   }

   func testTranformingToConfigurationDataFromConfiguration() {
      let expectedServerURL = "test.test"
      let configuration = Configuration(apiHost: expectedServerURL,
                                        functionsHost: "www.func.com",
                                        socketHost: "sockethost",
                                        sslCertificateData: Data(),
                                        companyName: "testName",
                                        termsAndConditions: "foobar")
      let actualServerURL = configuration.asData().apiHost
      XCTAssertEqual(expectedServerURL, actualServerURL)
   }
}
