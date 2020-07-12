//
//  Observable+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

enum UnrecoverableError: Error {
   /// Associated value is the original error.
   case `default`(Error)
}

extension Observable {
   /// Handle result, setting ready in our `LoadState` variable if `isReady` returns true.
   ///
   /// - Parameters:
   ///   - state: Will `setReady()` if `isReady` is true, otherwise it will `setLoading(false)`.
   ///   - isReady: Function that returns whether the result qualifies for a ready state.
   /// - Returns: Observable of self.
   func handleResult(updating state: BehaviorRelay<LoadState>, isReady: @escaping (Element) -> Bool) -> Observable<Element> {
      return `do`(onNext: { value in
         if isReady(value) {
            var value = state.value
            value.setReady()
            state.accept(value)
         } else {
            var value = state.value
            value.setLoading(false)
            state.accept(value)
         }
      })
   }

   /// Filters and rethrows unrecoverable errors.
   ///
   /// - Returns: Original error or `UnrecoverableError`.
   private func catchUnrecoverableError() -> Observable<Element> {
      return catchError { (error) -> Observable<Element> in
         if (error as NSError).isNetworkUnreachableError {
            return Observable.error(error)
         }

         if (error as NSError).isNetworkTimeoutError {
            return Observable.error(UnrecoverableError.default(error))
         }
         switch error {
         case CacheError.notFound:
            break
         default:
            return Observable.error(UnrecoverableError.default(error))
         }
         return Observable.error(error)
      }
   }

   /// Catch and handle common errors before returning the unrecoverable errors to a third party
   /// to resolve.
   ///
   /// - Parameters:
   ///   - suppressErrorIf: Error will be suppressed if true.
   ///   - emptyValue: Value to use when error is suppressed or `CacheError.notFound`.
   ///   - whenUnrecoverable: Function that handles an unrecoverable error returning an observable.
   /// - Returns: `Observable` that handles errors and retry when offline logic.
   func catchError(suppressErrorIf suppressed: Observable<Bool>,
                   emptyValue: Observable<Element> = .empty(),
                   whenUnrecoverable onError: @escaping (Error) -> Observable<Element>) -> Observable<Element> {
      return catchUnrecoverableError()
         .catchError { (error) -> Observable<Element> in
            switch error {
            case CacheError.notFound:
               return emptyValue
            case let UnrecoverableError.default(unrecoverableError):
               return suppressed.flatMap { (isSuppressed) -> Observable<Element> in
                  isSuppressed ? emptyValue : onError(unrecoverableError)
               }
            default:
               return .error(error)
            }
         }
   }
}

extension ObservableConvertibleType where Element == Void {
   func asDriver() -> Driver<Element> {
      return asDriver(onErrorJustReturn: ())
   }
}
