//
//  StreamPriceRepository.swift
//  Data
//
//  Created by Li Hao Lai on 11/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias StreamPriceRepositoryType = Streamable

class StreamPriceRepository: StreamPriceRepositoryType {
   typealias Key = GetPriceListRequest
   typealias Value = StreamPrice

   fileprivate let streamer: BasicCache<GetPriceListRequest, StreamPriceData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<StreamPriceData, StreamPrice>

   init(socketClient: SocketClient, currenciesStorage: CurrenciesStorage) {
      let streamRouterTransformer = RouterTransformer.streamPriceList()
      let streamPriceRransformer = StreamTransformer.price()
      let streamDataSource = SocketDataSource(apiClient: socketClient,
                                              keyTransformer: streamRouterTransformer,
                                              valueTransformer: streamPriceRransformer)

      streamer = streamDataSource.asBasicCache()

      let currencyRetrieval: (String) -> Observable<CurrencyData> = {
         currenciesStorage.get($0)
      }

      entityTransformer = DomainTransformer
         .streamPrice(using: currencyRetrieval)
   }
}

extension StreamPriceRepository {
   func stream(_ key: GetPriceListRequest) -> Observable<StreamPrice> {
      return streamer.get(key).flatMap(entityTransformer.transform)
   }
}
