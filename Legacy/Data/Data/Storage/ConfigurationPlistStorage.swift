//
//  ConfigurationPlistStorage.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

// swiftlint:disable identifier_name
/// Error that is thrown when `Configuration` cannot be read.

enum ConfigurationError: Error {
   /// Particular key is missing from configuration file.
   case missingKey(ConfigurationKey)
}

/// Keys that exist in the `Configuration` plists.

enum ConfigurationKey: String {
   /// Root path for all server communication.
   case apiHost

   /// Root path for all lambda functions.
   case functionsHost

   /// Name of the SSL certificate.
   case sslCertificateName

   /// Root path for socket server communication.
   case socketHost

   /// Company Name
   case companyName

   /// API Key
   case apiKey

   /// Terms and Conditions
   case termsAndConditions
}

/// The `ConfigurationPlistStorage` represents a configuration storage implementation based on a plist.

class ConfigurationPlistStorage: ConfigurationStorage {
   private let configurationPath: String
   private let bundle: Bundle

   /// Initialize `ConfigurationPlistStorage`.
   ///
   /// - Parameters:
   ///   - file: Name of file to read.
   ///   - type: Type of file to read.
   ///   - bundle: Bundle the file belongs to.
   /// - Throws: `ConfigurationError` if `configuration` file is missing.
   init(file: String = "Configuration", ofType type: String = "plist", inBundle bundle: Bundle) throws {
      guard let configurationPath = bundle.path(forResource: file, ofType: type) else {
         throw FileError.missing
      }
      self.configurationPath = configurationPath
      self.bundle = bundle
   }

   private func makeConfiguration() throws -> ConfigurationData {
      guard let configuration = NSDictionary(contentsOfFile: configurationPath) as? [String: Any] else {
         throw FileError.missing
      }
      var certificateData: Data?

      if let certificateName: String = try? configuration.value(for: .sslCertificateName) {
         guard let certificatePath = bundle.path(forResource: certificateName, ofType: "p12") else {
            throw FileError.missing
         }
         guard let data = try? Data(contentsOf: URL(fileURLWithPath: certificatePath)), data.isEmpty else {
            throw FileError.missing
         }
         certificateData = data
      }

      let host: String = try configuration.value(for: .apiHost)
      guard !host.isEmpty else {
         throw FileError.missing
      }

      let functionsHost: String = try configuration.value(for: .functionsHost)
      guard !functionsHost.isEmpty else {
         throw FileError.missing
      }

      let socketHost: String = try configuration.value(for: .socketHost)
      guard !socketHost.isEmpty else {
         throw FileError.missing
      }

      let companyName: String = try configuration.value(for: .companyName)
      guard !companyName.isEmpty else {
         throw FileError.missing
      }

      let apiKey: String = try configuration.value(for: .apiKey)
      guard !apiKey.isEmpty else {
         throw FileError.missing
      }

      let termsAndConditions: String = try configuration.value(for: .termsAndConditions)
      guard !termsAndConditions.isEmpty else {
         throw FileError.missing
      }

      return ConfigurationData(apiHost: host,
                               functionsHost: functionsHost,
                               socketHost: socketHost,
                               sslCertificateData: certificateData,
                               companyName: companyName,
                               apiKey: apiKey,
                               termsAndConditions: termsAndConditions)
   }

   override func get(_ key: String) -> Observable<ConfigurationData> {
      do {
         let configuration = try makeConfiguration()
         return Observable.just(configuration)
      } catch {
         return Observable.error(error)
      }
   }

   override func set(_ value: ConfigurationData, for key: String) -> Observable<Void> {
      // no op
      return Observable.just(())
   }
}

// MARK: - Helper

private extension Dictionary {
   /// Returns value for a given `ConfigurationKey`.
   ///
   /// - Parameter key: `ConfigurationKey` to find in dictionary.
   /// - Returns: Value for key.
   /// - Throws: `ConfigurationError` if `key` cannot be read.
   func value<T>(for key: ConfigurationKey) throws -> T {
      guard let result = filter({ $0.key.hashValue == key.rawValue.hashValue }).first?.value as? T else {
         throw ConfigurationError.missingKey(key)
      }
      return result
   }
}
