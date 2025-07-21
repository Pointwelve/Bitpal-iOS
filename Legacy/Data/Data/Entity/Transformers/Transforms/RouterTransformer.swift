//
//  RouterTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

/// Transforms `Key` into `Router` used by `APIClient`.

enum RouterTransformer {
   typealias RouterTransformerType = () -> ValueTransformerBox<String, Router>

   static func makeRouterTransformer(_ block: @escaping (String) -> Router) -> RouterTransformerType {
      return {
         ValueTransformerBox<String, Router>({ key in
            Observable.just(block(key))
         })
      }
   }

   static func streamPriceList() -> () -> ValueTransformerBox<GetPriceListRequest, Router> {
      return {
         ValueTransformerBox<GetPriceListRequest, Router>({ key in
            Observable
               .just(PriceSocketRouter.price(subscriptions: key.subscriptions))
         })
      }
   }

   static func historicalPriceList() -> () -> ValueTransformerBox<HistoricalPriceListRequest, Router> {
      return {
         ValueTransformerBox<HistoricalPriceListRequest, Router>({ key in

            Observable.just(PriceRouter.getHistoricalPriceList(key.routerType,
                                                               key.fromSymbol.symbol,
                                                               key.toSymbol.symbol,
                                                               key.exchange.name,
                                                               key.aggregate,
                                                               key.limit))
         })
      }
   }

   static func currencyDetail() -> () -> ValueTransformerBox<GetCurrencyDetailRequest, Router> {
      return {
         ValueTransformerBox<GetCurrencyDetailRequest, Router>({ key in
            Observable.just(PriceRouter.getCurrencyDetail(key.currencyPair.baseCurrency.symbol,
                                                          key.currencyPair.quoteCurrency.symbol,
                                                          key.currencyPair.exchange.name))
         })
      }
   }

   static func currencyPairList() -> RouterTransformerType {
      return makeRouterTransformer { _ in
         CurrenciesRouter.currencies
      }
   }

   static func registerPush() -> RouterTransformerType {
      return makeRouterTransformer { token in
         PushNotificationRouter.register(token)
      }
   }

   static func authenticationToken() -> RouterTransformerType {
      return makeRouterTransformer {
         AuthenticationRouter.authenticate(identifier: $0)
      }
   }

   static func updateWatchlist() -> () -> ValueTransformerBox<SetWatchlistRequest, Router> {
      return {
         ValueTransformerBox<SetWatchlistRequest, Router>({ key in
            let watchlistFireBaseList = key.currencyPairs.map { WatchlistFirebaseData(currenyPair: $0).serialized() }
            return Observable.just(WatchlistRouter.update(watchlistFireBaseList))
         })
      }
   }

   static func retrieveWatchlist() -> RouterTransformerType {
      return makeRouterTransformer { _ in
         WatchlistRouter.retrieve
      }
   }

   static func anonymousMigration() -> () -> ValueTransformerBox<AnonymousMigrationRequest, Router> {
      return {
         ValueTransformerBox<AnonymousMigrationRequest, Router>({ key in
            Observable.just(AnonymousRouter.migration(anonymousIdentifier: key.anonymousIdentifier,
                                                      override: key.override))
         })
      }
   }

   static func alertList() -> RouterTransformerType {
      return makeRouterTransformer { _ in
         AlertRouter.alerts
      }
   }

   static func createAlert() -> () -> ValueTransformerBox<CreateAlertRequest, Router> {
      return {
         ValueTransformerBox<CreateAlertRequest, Router> { (request) -> Observable<Router> in
            Observable.just(AlertRouter.create(request))
         }
      }
   }

   static func deleteAlert() -> () -> ValueTransformerBox<String, Router> {
      return {
         ValueTransformerBox<String, Router> { (id) -> Observable<Router> in
            Observable.just(AlertRouter.delete(id))
         }
      }
   }

   static func updateAlert() -> () -> ValueTransformerBox<Alert, Router> {
      return {
         ValueTransformerBox<Alert, Router> { (request) -> Observable<Router> in
            Observable.just(AlertRouter.update(request))
         }
      }
   }
}
