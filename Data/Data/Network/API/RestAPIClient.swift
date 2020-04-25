//
//  RestAPIClient.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Alamofire
import Domain
import Foundation
import RxAlamofire
import RxSwift

private enum HTTPHeaderField: String {
   case acceptLanguage = "Accept-Language"
   case authorization = "Authorization"
}

final class RestAPIClient: APIClient {
   typealias GetAction = (Router) -> Observable<(String, Language, (() -> Observable<String>)?)>
   typealias ReadAction = () -> Observable<Language?>

   private let apiSessionManager: Alamofire.Session
   private let readPreferencesAction: ReadAction
   private let getConfigurationAction: GetAction

   init(getConfigurationAction: @escaping GetAction, readPreferencesAction: @escaping ReadAction) {
      apiSessionManager = Alamofire.Session(configuration: .makeSessionConfigurationIgnoringHttpCache())
      self.getConfigurationAction = getConfigurationAction
      self.readPreferencesAction = readPreferencesAction
   }

   private func makeRequest(router: APIRouter, apiHost: String, language: Language, token: String?) -> URLRequest {
      var request = UrlRequestType.api(authorizationHeader: nil, router: router)
         .request(for: apiHost, language: language)
      if let formParameter = router.parameters,
         let encodedRequest = try? JSONEncoding.default.encode(request, with: formParameter) {
         request = encodedRequest
      }
      if let authorizationToken = token, router.authenticatable {
         request.setValue("Bearer \(authorizationToken)",
                          forHTTPHeaderField: HTTPHeaderField.authorization.rawValue)
      }

      return request
   }

   override func executeRequest(for router: Router) -> Observable<Any> {
      return readPreferencesAction()
         .flatMap { [weak self] language -> Observable<Any> in
            guard let `self` = self else {
               return .empty()
            }
            return self.getConfigurationAction(router).flatMap { (apiHost, preferredLanguage, authTokenGeneratorOptional) -> Observable<Any> in
               guard let authTokenGenerator = authTokenGeneratorOptional, let apiRouter = router as? APIRouter, apiRouter.authenticatable else {
                  // swiftlint:disable force_cast
                  let request = self.makeRequest(router: router as! APIRouter,
                                                 apiHost: apiHost,
                                                 language: language ?? preferredLanguage,
                                                 token: nil)
                  return self.apiSessionManager.rx
                     .request(urlRequest: request)
                     .json
               }

               return authTokenGenerator().flatMapLatest { token -> Observable<Any> in
                  let request = self.makeRequest(router: apiRouter,
                                                 apiHost: apiHost,
                                                 language: language ?? preferredLanguage,
                                                 token: token)
                  return self.apiSessionManager.rx
                     .request(urlRequest: request)
                     .json
               }
            }
         }
   }

   func replacing(readPreferencesAction newReadAction: @escaping ReadAction) -> RestAPIClient {
      return .init(getConfigurationAction: getConfigurationAction, readPreferencesAction: newReadAction)
   }
}

// MARK: - Helpers

private let validContentTypes = ["application/json"]
private let validStatusCodeRange = 200..<300

private extension Observable where Element: DataRequest {
   var json: Observable<Any> {
      return flatMap { $0
         .customValidate(statusCode: validStatusCodeRange)
         .validate(contentType: validContentTypes)
         .rx
         .responseJSON()
         .map { $0.value }
         .filterNil()
      }
   }
}

extension DataRequest {
   func customValidate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
      return validate { [unowned self] _, response, data in
         self.validate(statusCode: acceptableStatusCodes, response: response, data: data)
      }
   }
}

extension Request {
   private enum Key: String {
      case code
   }

   func validate<S: Sequence>(statusCode acceptableStatusCodes: S, response: HTTPURLResponse, data: Data?)
      -> ValidationResult where S.Iterator.Element == Int {
      if acceptableStatusCodes.contains(response.statusCode) {
         return .success(())
      }

      guard let data = data,
         let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
         json[Key.code.rawValue] != nil else {
         let reason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: response.statusCode)
         return .failure(AFError.responseValidationFailed(reason: reason))
      }

      return .success(())
   }
}
