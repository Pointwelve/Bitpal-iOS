//
//  UrlRequestTypeTests.swift
//  Domain
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

class TestableRouter: APIRouter {
   var method: HTTPMethodType {
      return .get
   }

   var relativePath: String {
      return "/relative"
   }

   var isOnboardingPath: Bool {
      return false
   }

   var parameters: [String: Any]? {
      return nil
   }

   var query: [URLQueryItem]? {
      return nil
   }

   var formParameters: [String: Any]? {
      return [:]
   }
}

public class UrlRequestTypeTests: XCTestCase {
   func testApiRequest() {
      let request = UrlRequestType.api(authorizationHeader: "header", router: TestableRouter()).request(for: "www.host.com", language: .en)
      guard let headers = request.allHTTPHeaderFields,
         let url = request.url else {
         XCTFail()
         return
      }
      XCTAssertTrue(headers.keys.contains(HTTPHeaderField.authorization("test").key))
      XCTAssertTrue(headers.keys.contains(HTTPHeaderField.acceptLanguage(.en).key))
      XCTAssertEqual(headers[HTTPHeaderField.authorization("test").key], "header")
      XCTAssertEqual(headers[HTTPHeaderField.acceptLanguage(.en).key], "en")
      XCTAssertEqual(url, URL(string: "https://www.host.com/relative")!)
   }
}
