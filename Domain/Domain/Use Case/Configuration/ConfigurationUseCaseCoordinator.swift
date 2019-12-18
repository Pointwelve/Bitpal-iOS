//
//  ConfigurationUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 5/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct ConfigurationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Configuration>

   public var apiHost: String {
      return configuration?.apiHost ?? ""
   }

   public var functionsHost: String {
      return configuration?.functionsHost ?? ""
   }

   public var socketHost: String {
      return configuration?.socketHost ?? ""
   }

   public var sslCertificateData: Data? {
      return configuration?.sslCertificateData
   }

   public var companyName: String {
      return configuration?.companyName ?? ""
   }

   public var termsAndConditions: String {
      return configuration?.termsAndConditions ?? ""
   }

   let configuration: Configuration?

   let readAction: ReadAction

   public init(configuration: Configuration? = nil, readAction: @escaping ReadAction) {
      self.configuration = configuration
      self.readAction = readAction
   }

   // MARK: - Requests

   func readRequest() -> Observable<Configuration> {
      return readAction()
   }

   // MARK: - Executors

   func read() -> Observable<ConfigurationUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   // MARK: - Result

   public func readResult() -> Observable<Result<ConfigurationUseCaseCoordinator>> {
      return result(from: read()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(configuration newConfiguration: Configuration) -> ConfigurationUseCaseCoordinator {
      return .init(configuration: newConfiguration, readAction: readAction)
   }
}
