//
//  RealmManager.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import Realm
import RealmSwift
import Security

// Purge of old realm files should only happen once.
private var purgedOnce = false

class RealmManager {
   var invalidated: Bool = false

   private let key: Data
   private let fileURL: URL
   internal let fileName: String
   private let fileExtension: String = ".realm"
   private let target: Target

   convenience init(with fileName: String?, target: Target = .app) {
      if let databaseName = fileName {
         self.init(fileName: databaseName, realmTarget: target)
      } else {
         // Create a "dummy" realm manager that doesn't actually write to realm
         self.init(dummy: true, target: target)
      }
   }

   init(fileName: String, key: Data = RealmKey.getKey() as Data, realmTarget: Target) {
      let fileManager = FileManager.default
      let documentsPath = fileManager
         .containerURL(forSecurityApplicationGroupIdentifier: "group.com.pointwelve.app.bitpal")?
         .absoluteString ?? ""
      let url = URL(fileURLWithPath: RLMRealmPathForFile("\(fileName)\(fileExtension)"), isDirectory: false)

      self.fileName = fileName
      fileURL = URL(string: "\(documentsPath)\(fileName)\(fileExtension)") ?? url

      self.key = key
      target = realmTarget

      migration()
      // Only purge once we know the filename
      purge()
   }

   init(dummy: Bool, target: Target) {
      key = Data()
      invalidated = true
      fileName = ""
      fileURL = URL(fileURLWithPath: "")

      self.target = target
   }

   private func purge() {
      if purgedOnce {
         return
      }
      purgedOnce = true

      let fileManager = FileManager.default
      let documentsPath = fileManager
         .containerURL(forSecurityApplicationGroupIdentifier: "group.com.pointwelve.app.bitpal")?
         .path ?? NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

      guard let contents = try? fileManager.contentsOfDirectory(atPath: documentsPath) else {
         return
      }

      let filePaths = contents.filter { !$0.contains(fileName) && $0.contains(fileExtension) }
         .map((documentsPath as NSString).appendingPathComponent)
      filePaths.forEach { filePath in
         if fileManager.isDeletableFile(atPath: filePath) {
            do {
               try fileManager.removeItem(atPath: filePath)
               debugPrint("Purged old Realm file: \(filePath)")
            } catch {
               debugPrint("Failed to purge: \(filePath)")
            }
         }
      }
   }

   /// Remove this migration function after all users upgrade to 1.3
   private func migration() {
      let fileManager = FileManager.default

      if target == .widget || fileManager.fileExists(atPath: fileURL.path) {
         return
      }

      let atURL = URL(fileURLWithPath: RLMRealmPathForFile("\(fileName)\(fileExtension)"), isDirectory: false)

      if fileManager.fileExists(atPath: atURL.path) {
         try? fileManager.moveItem(at: atURL, to: fileURL)
      }
   }

   func makeRealm() throws -> Realm {
      // All operations are blocked and will fail if this flag is set
      guard !invalidated else {
         throw FileError.accessDenied
      }

      // Prevent Widget createing realm db
      if target == .widget {
         let fileManager = FileManager.default

         if !fileManager.fileExists(atPath: fileURL.path) {
            throw FileError.accessDenied
         }
      }

      let configuration = Realm.Configuration(fileURL: fileURL,
                                              encryptionKey: key,
                                              deleteRealmIfMigrationNeeded: true)
      // Uncomment this line to show encryption key
      // debugPrint(key.reduce("") {$0 + String(format: "%02x", $1)})
      return try Realm(configuration: configuration)
   }

   func get<T: Object>(with id: String) throws -> T {
      guard let realm = try? makeRealm() else {
         // TODO: rynecheow 21/4/17 Gracefully delete realm and recreate
         throw FileError.accessDenied
      }
      guard let object = realm.object(ofType: T.self, forPrimaryKey: id) else {
         throw CacheError.notFound
      }
      return object
   }

   /// Remove orphaned children caused by weak relationships due to circular references
   /// and objects having multiple parents.
   func removeOrphanedChildren<T: Object>(of parent: T) throws {
      if let parentType = parent as? ParentType {
         // Go through children of the current object,
         // check if they have more than one parent remaining
         // if so, keep them, if not delete them.

         var orphaned = [Object]()
         parentType.children.forEach { child in
            // Check if child is already orphaned
            // swiftlint:disable force_cast
            let isAlreadyOrphaned = orphaned.filter { $0 == child as! Object }.isNotEmpty

            // Check if child has no parents
            // swiftlint:disable force_cast
            let isOrphaned = child.parents.map { $0 as! Object }.filter { $0 != parent }.isEmpty

            // Add child to orphaned objects if it has no parents
            if isOrphaned, !isAlreadyOrphaned { // swiftlint:disable force_cast
               orphaned.append(child as! Object)
            }
         }

         for orphan in orphaned {
            try delete(orphan)
         }
      }
   }

   func delete<T: Object>(_ object: T) throws {
      guard let realm = try? makeRealm() else {
         // TODO: rynecheow 21/4/17 Gracefully delete realm and recreate
         throw FileError.accessDenied
      }
      do {
         try removeOrphanedChildren(of: object)
         try realm.write {
            if let cascadable = object as? RealmCascadeDeletable {
               let objects = cascadable.cascadeDeleteObjects()
               realm.delete(objects)
            }
            realm.delete(object)
         }
      } catch {
         throw CacheError.invalid
      }
   }

   func list<T: Object>() throws -> [T] {
      guard let realm = try? makeRealm() else {
         // TODO: rynecheow 21/4/17 Gracefully delete realm and recreate
         throw FileError.accessDenied
      }
      return realm.objects(T.self).map { $0 }
   }

   func set<T: Object>(_ object: T) throws -> T {
      guard let realm = try? makeRealm() else {
         // TODO: rynecheow 21/4/17 Gracefully delete realm and recreate
         throw FileError.accessDenied
      }
      do {
         try realm.write {
            realm.add(object, update: .all)
         }
         return object
      } catch {
         throw CacheError.invalid
      }
   }
}

class RealmKey {
   static func getKey() -> Data {
      // Identifier for our keychain entry - should be unique for your application
      let keychainIdentifier = "io.App.EncryptionKey"
      let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!

      // First check in the keychain for an existing key
      var query: [NSString: AnyObject] = [
         kSecClass: kSecClassKey,
         kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
         kSecAttrKeySizeInBits: 512 as AnyObject,
         kSecReturnData: true as AnyObject,
         kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
      ]

      // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
      // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
      var dataTypeRef: AnyObject?
      var status = withUnsafeMutablePointer(to: &dataTypeRef) {
         SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
      }
      if status == errSecSuccess {
         // swiftlint:disable force_cast
         return dataTypeRef as! Data
      }

      // Second check in the keychain for an existing key (previous version)
      query.removeValue(forKey: kSecAttrAccessible)

      // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
      // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
      status = withUnsafeMutablePointer(to: &dataTypeRef) {
         SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
      }
      if status == errSecSuccess {
         query.removeValue(forKey: kSecReturnData)
         let updatedQuery: [NSString: AnyObject] = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock]

         status = SecItemUpdate(query as CFDictionary, updatedQuery as CFDictionary)
         assert(status == errSecSuccess, "Failed to update in the existing keychain")

         // swiftlint:disable force_cast
         return dataTypeRef as! Data
      }

      // No pre-existing key from this application, so generate a new one
      let keyData = NSMutableData(length: 64)!
      let result = SecRandomCopyBytes(kSecRandomDefault,
                                      64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
      assert(result == 0, "Failed to get random bytes")

      // Store the key in the keychain
      query = [
         kSecClass: kSecClassKey,
         kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
         kSecAttrKeySizeInBits: 512 as AnyObject,
         kSecValueData: keyData,
         kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
      ]

      status = SecItemAdd(query as CFDictionary, nil)
      assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

      // swiftlint:disable force_cast
      return keyData.copy() as! Data
   }
}
