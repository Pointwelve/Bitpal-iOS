//
//  PriceRouter.swift
//  Domain
//
//  Created by Li Hao Lai on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum PriceRouter: APIRouter {
   private enum UrlQueryKey: String {
      case fsym
      case fsyms
      case tsym
      case tsyms
      case exchange = "e"
      case aggregate
      case limit
      case extraParams
      case sign
      case allData
   }

   case getPriceList([String], [String], String)
   case getHistoricalPriceList(PriceHistoRouterType, String, String, String, Int, Int)
   case getCurrencyDetail(String, String, String)

   public var relativePath: String {
      switch self {
      case .getPriceList:
         return "/data/pricemulti"
      case let .getHistoricalPriceList(routerType, _, _, _, _, _):
         return routerType.url
      case .getCurrencyDetail:
         return "/data/pricemultifull"
      }
   }

   public var method: HTTPMethodType {
      return .get
   }

   public var query: [URLQueryItem]? {
      var queryItem: [URLQueryItem] = [URLQueryItem(name: UrlQueryKey.sign.rawValue, value: "\(true)")]

      if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
         queryItem.append(URLQueryItem(name: UrlQueryKey.extraParams.rawValue, value: appName))
      }

      switch self {
      case let .getPriceList(fromSymbols, toSymbols, exchange):
         let fromSymbolsValue = fromSymbols.joined(separator: ",")
         let toSymbolsValue = toSymbols.joined(separator: ",")

         queryItem.append(contentsOf: [
            URLQueryItem(name: UrlQueryKey.fsyms.rawValue, value: fromSymbolsValue),
            URLQueryItem(name: UrlQueryKey.tsyms.rawValue, value: toSymbolsValue),
            URLQueryItem(name: UrlQueryKey.exchange.rawValue, value: exchange)
         ])

      case let .getHistoricalPriceList(_, fromSymbol, toSymbol, exchange, aggregate, limit):
         queryItem.append(contentsOf: [
            URLQueryItem(name: UrlQueryKey.fsym.rawValue, value: fromSymbol),
            URLQueryItem(name: UrlQueryKey.tsym.rawValue, value: toSymbol),
            URLQueryItem(name: UrlQueryKey.exchange.rawValue, value: exchange),
            URLQueryItem(name: UrlQueryKey.aggregate.rawValue, value: "\(aggregate)"),
            URLQueryItem(name: UrlQueryKey.limit.rawValue, value: "\(limit)")
         ])
      case let .getCurrencyDetail(fromSymbol, toSymbol, exchange):
         queryItem.append(contentsOf: [
            URLQueryItem(name: UrlQueryKey.fsyms.rawValue, value: fromSymbol),
            URLQueryItem(name: UrlQueryKey.tsyms.rawValue, value: toSymbol),
            URLQueryItem(name: UrlQueryKey.exchange.rawValue, value: exchange)
         ])
      }
      return queryItem
   }
}
