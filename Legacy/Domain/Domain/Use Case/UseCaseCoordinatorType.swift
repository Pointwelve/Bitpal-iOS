//
//  UseCaseCoordinatorType.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

/// Responsible for coordinating use cases, returning sanitised responses.
public protocol UseCaseCoordinatorType {}

extension UseCaseCoordinatorType {
   func result<T>(from input: Observable<T>) -> Observable<Result<T>> {
      return input
         .map { .content(.with($0, .full)) }
         .catchError { (error) -> Observable<Result<T>> in
            .just(.failure(.error(error)))
         }
         .flatMap { (response) -> Observable<Result<T>> in
            switch response {
            case let .failure(.error(error)):
               if response.isOffline {
                  return .just(.failure(.offline))
               } else {
                  switch error {
                  case CacheError.expired:
                     return .just(.failure(.expired))
                  case CacheError.notFound:
                     return .just(.failure(.nothing))
                  default:
                     return .just(response)
                  }
               }
            default:
               return .just(response)
            }
         }
         .catchError { (error) -> Observable<Result<T>> in
            .just(.failure(.error(error)))
         }
   }
}
