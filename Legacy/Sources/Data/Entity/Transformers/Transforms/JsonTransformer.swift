//
//  JsonTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxOptional
import RxSwift

/// Transforms `Json` into `DataType`.

enum JsonTransformer {
   typealias JsonTransformerType<T: DataType & JsonDeserializable> = (String) -> ValueTransformerBox<Any, T>
   typealias JsonTransformerWithRequestType<K: RequestType, T: DataType & JsonDeserializable>
      = (K) -> ValueTransformerBox<Any, T>

   fileprivate static func makeJsonTransformer<T: DataType & JsonDeserializable>() -> JsonTransformerType<T> {
      return { _ in
         makeJsonTransformer(customInitializer: { (json) -> T in
            try T(json: json)
         })
      }
   }

   fileprivate static func makeJsonTransformer<K: RequestType, T: DataType & JsonDeserializable>()
      -> JsonTransformerWithRequestType<K, T> {
      return { _ in
         makeJsonTransformer(customInitializer: { (json) -> T in
            try T(json: json)
         })
      }
   }

   fileprivate static func makeJsonTransformer<T: DataType & JsonDeserializable>
   (customInitializer: @escaping (Any) throws -> T) -> ValueTransformerBox<Any, T> {
      return ValueTransformerBox<Any, T>({ json -> Observable<T> in
         do {
            let object = try customInitializer(json)
            return .just(object)
         } catch {
            return .error(error)
         }
      })
   }

   static func historicalPrice() -> (HistoricalPriceListRequest) -> ValueTransformerBox<Any, HistoricalPriceListData> {
      return { request in
         makeJsonTransformer(customInitializer: { (json) -> HistoricalPriceListData in
            try HistoricalPriceListData(json: json, fromCurrency: request.fromSymbol.symbol,
                                        toCurrency: request.toSymbol.symbol, exchange: request.exchange.name)
         })
      }
   }

   static func currencyPairList() -> (String) -> ValueTransformerBox<Any, CurrencyPairListData> {
      return { request in
         makeJsonTransformer(customInitializer: { (json) -> CurrencyPairListData in
            try CurrencyPairListData(json: json, id: request)
         })
      }
   }

   static func currencyDetail() -> (GetCurrencyDetailRequest) -> ValueTransformerBox<Any, CurrencyDetailData> {
      return { request in
         makeJsonTransformer(customInitializer: { (json) -> CurrencyDetailData in
            try CurrencyDetailData(json: json, currencyPair: request.currencyPair)
         })
      }
   }

   static func authenticationToken() -> JsonTransformerType<AuthenticationTokenData> {
      return makeJsonTransformer()
   }

   static func updateWatchlist() -> (SetWatchlistRequest) -> ValueTransformerBox<Any, WatchlistData> {
      return { _ in
         makeJsonTransformer(customInitializer: { (json) -> WatchlistData in
            try WatchlistData(json: json)
         })
      }
   }

   static func getWatchlist() -> JsonTransformerType<WatchlistData> {
      return makeJsonTransformer()
   }

   static func anonymousMigration()
      -> JsonTransformerWithRequestType<AnonymousMigrationRequest, AnonymousMigrationResponseData> {
      return makeJsonTransformer()
   }

   static func standardResponse() -> JsonTransformerType<StandardResponseData> {
      return makeJsonTransformer()
   }

   static func alertList() -> JsonTransformerType<AlertListData> {
      return makeJsonTransformer()
   }

   static func createAlert() -> JsonTransformerWithRequestType<CreateAlertRequest, CreateAlertResponseData> {
      return makeJsonTransformer()
   }

   static func updateAlert() -> JsonTransformerWithRequestType<Alert, UpdateAlertResponseData> {
      return makeJsonTransformer()
   }
}
