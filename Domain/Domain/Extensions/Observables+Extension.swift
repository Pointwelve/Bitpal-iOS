//
//  Observables+Extension.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

extension Observable {
   /// Same as `Observable.just` however, it will return `error` if `block` throws.
   ///
   /// - Parameter block: Potentially throwable block to call.
   /// - Returns: `Observable` of type `just` or `error`.
   public static func justTry(_ block: () throws -> Element) -> Observable<Element> {
      do {
         let object = try block()
         return Observable.just(object)
      } catch {
         debugPrint(error)
         return Observable.error(error)
      }
   }

   /// Try to get an `Observable` by executing a block within a try, it will return `error` if `block` throws.
   ///
   /// - Parameter block: Potentially throwable block to call.
   /// - Returns: `Observable` or `error`.
   public static func `try`(_ block: () throws -> (Observable<Element>)) -> Observable<Element> {
      do {
         let object = try block()
         return object
      } catch {
         debugPrint(error)
         return .error(error)
      }
   }
}

extension ObservableType {
   public func retryOnError(every timeIntervalInSeconds: Int) -> Observable<Element> {
      return retryWhen { (attempts: Observable<Error>) -> Observable<Int> in
         Observable.zip(attempts, Observable.just(timeIntervalInSeconds)) {
            return $1
         }
         .flatMap {
            return Observable.timer(.seconds($0), period: .seconds($0),
                                    scheduler: MainScheduler.instance)
         }
      }
   }
}
