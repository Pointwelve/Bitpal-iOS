//
//  RealmTranformTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Foundation
import RealmSwift
import XCTest

class RealmTranformTests: XCTestCase {
   func testAsRealmLists() {
      let dataA = TestableRealmConvertible(value: 1)
      let dataB = TestableRealmConvertible(value: 2)

      let realmArray = [dataA, dataB]
      let realmList = realmArray.asRealmList()

      XCTAssertEqual(realmList.count, realmArray.count)

      zip(realmList, realmArray).forEach {
         a, b in
         XCTAssertEqual(a.value, b.value)
      }
   }

   func testAsRealmArray() {
      let objectA = TestableRealmObject()
      objectA.id = "A"
      objectA.value = 1

      let objectB = TestableRealmObject()
      objectB.id = "B"
      objectB.value = 2

      let realmList = List<TestableRealmObject>()
      [objectA, objectB].forEach(realmList.append)
      let realmArray = realmList.asArray()

      XCTAssertEqual(realmList.count, realmArray.count)

      zip(realmList, realmArray).forEach {
         a, b in
         XCTAssertEqual(a, b)
      }
   }
}
