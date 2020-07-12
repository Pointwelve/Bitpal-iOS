//
//  DomainTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

/// Transform between `Domain` and `Data` types.

enum DomainTransformer {
   typealias DomainTransformerType<T, U> = BidirectionalValueTransformerBox<T, U>

   private static func makeDomainTransformer<T: DomainConvertible & DataType,
                                             U: DataConvertible & DomainType>()
      -> DomainTransformerType<T, U> where T.DomainType == U, U.DataType == T {
      return makeDomainTransformer(customDomainInitializer: { $0.asDomain() },
                                   customDataInitializer: { $0.asData() })
   }

   private static func makeDomainTransformer<T: DomainConvertible & DataType,
                                             U: DataConvertible & DomainType>
   (customDomainInitializer: @escaping (T) -> U, customDataInitializer: @escaping (U) -> T)
      -> DomainTransformerType<T, U> where T.DomainType == U, U.DataType == T {
      return BidirectionalValueTransformerBox({ data in
         Observable.just(customDomainInitializer(data))
      }, { domain in
         Observable.just(customDataInitializer(domain))
      })
   }

   private static func makeDomainTransformer<T: DomainConvertible & DataType,
                                             U: DataConvertible & DomainType>
   (customObservableDomainInitializer: @escaping (T) -> (Observable<U>),
    customObservableDataInitializer: @escaping (U) -> (Observable<T>))
      -> DomainTransformerType<T, U> where T.DomainType == U, U.DataType == T {
      return BidirectionalValueTransformerBox({ data in
         customObservableDomainInitializer(data)
      }, { domain in
         customObservableDataInitializer(domain)
      })
   }

   static func configuration() -> DomainTransformerType<ConfigurationData, Configuration> {
      return makeDomainTransformer()
   }

   static func preferences() -> DomainTransformerType<PreferencesData, Preferences> {
      return makeDomainTransformer()
   }

   static func currencyPairList() -> DomainTransformerType<CurrencyPairListData, CurrencyPairList> {
      return makeDomainTransformer()
   }

   static func authenticationToken() -> DomainTransformerType<AuthenticationTokenData, AuthenticationToken> {
      return makeDomainTransformer()
   }

   static func deviceFingerprint() -> DomainTransformerType<DeviceFingerprintData, DeviceFingerprint> {
      return makeDomainTransformer()
   }

   static func streamPrice(using currencyRetrieval: @escaping (String) -> Observable<CurrencyData>)
      -> DomainTransformerType<StreamPriceData, StreamPrice> {
      return makeDomainTransformer(customObservableDomainInitializer: { data in
         Observable.combineLatest(currencyRetrieval(data.baseCurrency),
                                  currencyRetrieval(data.quoteCurrency)).map { baseCurrency, quoteCurrency in
            StreamPrice(type: PriceStreamType(rawValue: data.type)!,
                        exchange: Exchange(id: data.exchange, name: data.exchange),
                        baseCurrency: baseCurrency.asDomain(),
                        quoteCurrency: quoteCurrency.asDomain(),
                        priceChange: PriceChange(rawValue: data.priceChange)
                           ?? .unchanged,
                        price: data.price, bid: data.bid, offer: data.offer,
                        lastUpdateTimeStamp: data.lastUpdateTimeStamp,
                        avg: data.avg,
                        lastVolume: data.lastVolume,
                        lastVolumeTo: data.lastVolumeTo,
                        lastTradeId: data.lastTradeId, volumeHour: data.volumeHour,
                        volumeHourTo: data.volumeHourTo, volume24h: data.volume24h,
                        volume24hTo: data.volume24hTo, openHour: data.openHour,
                        highHour: data.highHour, lowHour: data.lowHour,
                        open24Hour: data.open24Hour,
                        high24Hour: data.high24Hour, low24Hour: data.low24Hour,
                        lastMarket: data.lastMarket,
                        mask: data.mask)
         }
      }, customObservableDataInitializer: { domain in
         Observable.just(domain.asData())
      })
   }

   static func historicalPriceList(using currencyRetrieval: @escaping (String) -> Observable<CurrencyData>)
      -> DomainTransformerType<HistoricalPriceListData, HistoricalPriceList> {
      return makeDomainTransformer(customObservableDomainInitializer: { data in
         Observable.combineLatest(currencyRetrieval(data.baseCurrency),
                                  currencyRetrieval(data.quoteCurrency)).map { baseCurrency, quoteCurrency in
            HistoricalPriceList(baseCurrency: baseCurrency.asDomain(),
                                quoteCurrency: quoteCurrency.asDomain(),
                                exchange: Exchange(id: data.exchange,
                                                   name: data.exchange),
                                historicalPrices: data.historicalPrices
                                   .asDomain(),
                                modifyDate: data.modifyDate)
         }
      }, customObservableDataInitializer: { domain in
         Observable.just(domain.asData())
      })
   }

   static func watchlist() -> DomainTransformerType<WatchlistData, Watchlist> {
      return makeDomainTransformer()
   }

   static func currencyPair() -> DomainTransformerType<CurrencyPairData, CurrencyPair> {
      return makeDomainTransformer()
   }

   static func currencyDetail()
      -> DomainTransformerType<CurrencyDetailData, CurrencyDetail> {
      return makeDomainTransformer()
   }

   static func anonymousMigrationResponse()
      -> DomainTransformerType<AnonymousMigrationResponseData, AnonymousMigrationResponse> {
      return makeDomainTransformer()
   }

   static func alertList() -> DomainTransformerType<AlertListData, AlertList> {
      return makeDomainTransformer()
   }
}
