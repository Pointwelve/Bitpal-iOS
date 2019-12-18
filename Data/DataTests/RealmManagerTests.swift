//
//  RealmManagerTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RealmSwift
import XCTest

class TestableRealmManager: RealmManager {
   let id = UUID().uuidString

   init() {
      super.init(dummy: true, target: .app)
   }

   override func makeRealm() throws -> Realm {
      return try! Realm(configuration: .init(inMemoryIdentifier: id))
   }
}

class TestObject: Object {
   @objc dynamic var id = ""

   override static func primaryKey() -> String? {
      return "id"
   }
}

class TestParent: TestObject, ParentType {
   @objc dynamic var childId = ""

   var child: TestChild? {
      return realm?.object(ofType: TestChild.self, forPrimaryKey: childId)
   }

   var children: [ChildType] {
      guard let child = child else {
         return []
      }
      return [child]
   }
}

class TestChild: TestObject, ChildType {
   var parents: [ParentType] {
      return realm?.objects(TestParent.self).filter { $0.childId == id } ?? []
   }
}

class TestGrandParent: TestObject, ParentType {
   @objc dynamic var childId = ""

   var child: TestGrandParentChild? {
      return realm?.object(ofType: TestGrandParentChild.self, forPrimaryKey: childId)
   }

   var children: [ChildType] {
      guard let child = child else {
         return []
      }
      return [child]
   }
}

class TestGrandParentChild: TestObject, ParentType, ChildType {
   @objc dynamic var childId = ""

   var child: TestGrandChild? {
      return realm?.object(ofType: TestGrandChild.self, forPrimaryKey: childId)
   }

   var children: [ChildType] {
      guard let child = child else {
         return []
      }
      return [child]
   }

   var parents: [ParentType] {
      return realm?.objects(TestGrandParent.self).filter { $0.childId == id } ?? []
   }
}

class TestGrandChild: TestObject, ChildType {
   var parents: [ParentType] {
      return realm?.objects(TestGrandParentChild.self).filter { $0.childId == id } ?? []
   }
}

class RealmManagerTests: XCTestCase {
   func testProductListDeleteCascades() {
      let manager = TestableRealmManager()
      let item = TestableRealmObject()
      item.id = "abcd"

      _ = try! manager.set(item)
      _ = try! manager.delete(item)

      let gotItem: TestableRealmObject? = try? manager.get(with: "abcd")

      XCTAssertNil(gotItem)
   }

   func testChildRemainsIfOnlyOneParentIsDeleted() {
      let manager = TestableRealmManager()

      let child = TestChild()
      child.id = "child_id"

      let parentA = TestParent()
      parentA.id = "parent_a"
      parentA.childId = child.id

      let parentB = TestParent()
      parentB.id = "parent_b"
      parentB.childId = child.id

      _ = try! manager.set(child)
      _ = try! manager.set(parentA)
      _ = try! manager.set(parentB)

      try! manager.delete(parentA)

      let gotChild: TestChild = try! manager.get(with: "child_id")

      XCTAssertEqual(gotChild.parents.count, 1)
   }

   func testChildIsDeletedIfOrphaned() {
      let manager = TestableRealmManager()

      let child = TestChild()
      child.id = "child_id"

      let parentA = TestParent()
      parentA.id = "parent_a"
      parentA.childId = child.id

      let parentB = TestParent()
      parentB.id = "parent_b"
      parentB.childId = child.id

      _ = try! manager.set(child)
      _ = try! manager.set(parentA)
      _ = try! manager.set(parentB)

      try! manager.delete(parentA)
      try! manager.delete(parentB)

      let gotChild: TestChild? = try? manager.get(with: "child_id")

      XCTAssertNil(gotChild)
   }

   func testRecursiveChildDeletion() {
      let manager = TestableRealmManager()

      let child = TestGrandChild()
      child.id = "child_id"

      let parent = TestGrandParentChild()
      parent.id = "parent_id"
      parent.childId = child.id

      let grandparent = TestGrandParent()
      grandparent.id = "grandparent_id"
      grandparent.childId = parent.id

      _ = try! manager.set(child)
      _ = try! manager.set(parent)
      _ = try! manager.set(grandparent)

      try! manager.delete(grandparent)

      let gotChild: TestGrandChild? = try? manager.get(with: "child_id")

      XCTAssertNil(gotChild)
   }

   func testRealmManagerGetReturnsObject() {
      let manager = TestableRealmManager()
      let testObject = TestObject()
      testObject.id = "test.id"
      _ = try! manager.set(testObject)

      do {
         let returnedObject: TestObject = try manager.get(with: "test.id")
         XCTAssertEqual(returnedObject.id, testObject.id)
      } catch {
         XCTFail()
      }
   }

   func testRealmManagerGetThrowsErrorIfObjectDoesNotExist() {
      let manager = TestableRealmManager()
      do {
         let _: TestObject = try manager.get(with: "test.id")
         XCTFail()
      } catch {
         switch error {
         case CacheError.notFound:
            XCTAssertTrue(true)
         default:
            XCTFail()
         }
      }
   }

   func testRealmManagerSetReturnsObject() {
      let manager = TestableRealmManager()
      let testObject = TestObject()
      testObject.id = "test.id"
      do {
         let returnedObject: TestObject = try manager.set(testObject)
         XCTAssertEqual(returnedObject.id, testObject.id)
      } catch {
         XCTFail()
      }
   }

   func testRealmManagerDeleteDoesThrow() {
      let manager = TestableRealmManager()
      let testObject = TestObject()
      testObject.id = "test.id"
      _ = try! manager.set(testObject)
      do {
         try manager.delete(testObject)
         XCTAssertTrue(true)
      } catch {
         XCTFail()
      }
   }
}
