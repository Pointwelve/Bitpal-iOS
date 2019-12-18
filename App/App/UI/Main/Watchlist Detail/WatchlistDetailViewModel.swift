//
//  WatchlistDetailViewModel.swift
//  App
//
//  Created by Kok Hong Choo on 13/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Domain
import RxCocoa
import RxDataSources
import RxSwift

final class WatchlistDetailViewModel: TransformableViewModelType, Navigable {
   weak var navigator: WatchlistDetailNavigatorType!

   init(navigator: WatchlistDetailNavigatorType) {
      self.navigator = navigator
   }

   struct Input {
      let watchlistButtonClicked: Driver<Void>
      let selectedChartPeriod: Driver<ChartPeriod>
      let highlightData: Driver<Highlight>
      let candleStickDataEntry: Driver<ChartDataEntry>
      let didTapPriceAlert: Driver<Void>
      let viewWillAppearDriver: Driver<Void>
      let didTapchartTypeBarButton: Driver<Void>
   }

   struct Output {
      let currencyPair: CurrencyPair
      let watchlistButtonClicked: Driver<Void>
      let currencyDetail: Driver<CurrencyDetail>
      let watchlistDetailData: Driver<[WatchlistDetailData]>
      let historicalPriceResult: Driver<Void>
      let candleGraphData: Driver<ChartData>
      let lineGraphData: Driver<ChartData>
      let selectedPriceText: Driver<String>
      let candleStickSelectedPriceText: Driver<String>
      let selectedDateText: Driver<String>
      let historicalPriceIsLoading: Driver<Bool>
      let currencyDetailResult: Driver<Void>
      let loadStateViewModel: LoadStateViewModel
      let price: Driver<String>
      let priceChangePctPriceChange: Driver<PriceChange>
      let didTapPriceAlert: Driver<Void>
      let isUpdateAlert: Driver<Bool>
      let graphType: Driver<ChartType>
      let didTapChartTypeBarButton: Driver<ChartType>
   }

   fileprivate typealias VisibleRowAndCurrencyPair = (rows: [Int], currencyPairs: [CurrencyPair])

   // swiftlint:disable cyclomatic_complexity function_body_length
   func transform(input: Input) -> Output {
      func getCurrencyDetail(_ request: GetCurrencyDetailRequest) -> Driver<Result<CurrencyDetailUseCaseCoordinator>> {
         return navigator.state.preferences
            .serviceProvider.repository
            .prices.currencyDetail(request: request)
            .getResult()
            .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
      }

      func historicalPrice(_ request: HistoricalPriceListRequest) ->
         Driver<Result<HistoricalPriceListUseCaseCoordinator>> {
         return navigator.state.preferences
            .serviceProvider.repository
            .prices.historicalPrice(request: request)
            .getResult()
            .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
      }

      let watchlistButtonClicked = input.watchlistButtonClicked
         .do(onNext: { [weak self] _ in
            self?.navigator.dismissWatchlistDetail()
         })

      let request = GetCurrencyDetailRequest(currencyPair: navigator.currencyPair)

      let currencyDetail = BehaviorRelay<CurrencyDetail?>(value: nil)
      let currencyDetailError = BehaviorRelay<Error?>(value: nil)

      let currencyDetailResult = getCurrencyDetail(request)
         .do(onNext: { result in
            switch result.flattened {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     currencyDetailError.accept(nil)
                     currencyDetail.accept(coordinator.currencyDetail)
                  default:
                     break
                  }
               }
            case let .failure(failure):
               switch failure {
               case let .error(error):
                  currencyDetailError.accept(error)
               default:
                  break
               }
            default:
               break
            }
         })
         .void()

      let watchlistDetailData = Driver.just(WatchlistDetailData.defaultData)

      let historicalPriceData = BehaviorRelay<HistoricalPriceList?>(value: nil)
      let historicalPriceError = BehaviorRelay<Error?>(value: nil)

      let baseCurrency = navigator.currencyPair.baseCurrency
      let quoteCurrency = navigator.currencyPair.quoteCurrency
      let exchange = navigator.currencyPair.exchange

      let historicalPriceAction = input.selectedChartPeriod
         .map { $0.historicalRequest(from: baseCurrency,
                                     toCurrency: quoteCurrency,
                                     exchange: exchange)
         }
         .flatMapLatest { request in
            historicalPrice(request)
         }

      let historicalPriceResult = historicalPriceAction
         .do(onNext: { result in
            switch result.flattened {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     historicalPriceError.accept(nil)
                     historicalPriceData.accept(coordinator.historicalPriceList)
                  default:
                     break
                  }
               }
            case let .failure(failure):
               switch failure {
               case let .error(error):
                  historicalPriceError.accept(error)
               default:
                  break
               }
            default:
               break
            }
         })
         .void()

      let historicalPriceIsLoading = historicalPriceAction.map { $0.isLoading }

      let candleGraphData = historicalPriceData.asDriver()
         .filterNil()
         .map { ChartDataHelper.convertToDetailCandleChartData(from: $0.historicalPrices) }

      let lineGraphData = Driver
         .combineLatest(historicalPriceData.asDriver().filterNil(), ThemeProvider.current)
         .map { ChartDataHelper.convertToDetailLineChartData(from: $0.historicalPrices, theme: $1) }

      let price = currencyDetail.asDriver()
         .filterNil()
         .map { "\($0.toDisplaySymbol) \($0.price.formatUsingSignificantDigits())" }

      let selectedPrice = input.highlightData
         .withLatestFrom(currencyDetail.asDriver().filterNil()) { ($0, $1) }
         .map { "\($0.1.toDisplaySymbol) \($0.0.y.formatUsingSignificantDigits())" }

      let candleStickSelectedPrice = input.candleStickDataEntry
         .withLatestFrom(currencyDetail.asDriver().filterNil()) { ($0, $1) }
         .map { (chartData, currencyDetail) -> String in
            guard let historicalPrice = chartData.data as? HistoricalPrice else {
               return ""
            }

            let open = "O: \(currencyDetail.toDisplaySymbol) \(historicalPrice.open.formatUsingSignificantDigits())  "
            let close = "C: \(currencyDetail.toDisplaySymbol) \(historicalPrice.close.formatUsingSignificantDigits())\n"
            let high = "H: \(currencyDetail.toDisplaySymbol) \(historicalPrice.high.formatUsingSignificantDigits())  "
            let low = "L: \(currencyDetail.toDisplaySymbol) \(historicalPrice.low.formatUsingSignificantDigits())"

            return open + close + high + low
         }

      let lineChartHighlightDate = input.highlightData
         .map {
            $0.x
         }

      let candleStickDataEntry = input.candleStickDataEntry
         .map { data -> Double in
            guard let historicalPrice = data.data as? HistoricalPrice else {
               return 0.0
            }

            return Double(historicalPrice.time)
         }

      let selectedDate = Driver.merge(lineChartHighlightDate, candleStickDataEntry)
         .map { data -> String in
            let date = Date(timeIntervalSince1970: data)
            return DateFormat
               .standardReadableDateFormat
               .string(from: date)
               .uppercased()
         }

      let loadStateViewModel = LoadStateViewModel()

      let isError = Driver.combineLatest(currencyDetailError.asDriver(),
                                         historicalPriceError.asDriver()) { $0 != nil || $1 != nil }

      let loadState = isError.map { $0 ? LoadState.error : LoadState.ready }
      _ = loadStateViewModel.transform(input: .init(navigator: navigator,
                                                    strategy: .watchlist,
                                                    loadState: loadState))

      let priceChangePctPriceChange = currencyDetail.asDriver()
         .filterNil()
         .map { $0.changePct24hour.priceChangeIn24HPct() }

      let updateAlertIcon = BehaviorRelay<Void>(value: ())

      let createAlertCompletionBlock = {
         updateAlertIcon.accept(())
      }

      let didTapPriceAlert = input.didTapPriceAlert
         .withLatestFrom(currencyDetail.asDriver().filterNil())
         .withLatestFrom(ThemeProvider.current) { ($0, $1) }
         .do(onNext: { [weak self] detail, theme in
            self?.navigator.showCreatePriceAlert(with: detail,
                                                 presentr: theme.createAlertPresentr,
                                                 completion: createAlertCompletionBlock)
         })
         .void()

      let isUpdateAlert = updateAlertIcon.asDriver()
         .flatMap { [weak self] () -> Driver<Bool> in
            guard let `self` = self else { return .just(false) }

            return self.navigator.state.preferences.serviceProvider.repository.alert
               .alerts()
               .getResult()
               .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
               .filter { $0.hasContent }
               .map { $0.contentValue?.alertList }
               .map { [weak self] alertList -> Bool in
                  guard let currencyPair = self?.navigator.currencyPair else {
                     return false
                  }

                  if let alertList = alertList {
                     for alert in alertList.alerts
                        where alert.pair == "\(currencyPair.baseCurrency.symbol)_\(currencyPair.quoteCurrency.symbol)" &&
                        alert.exchange == currencyPair.exchange.name {
                        return true
                     }
                  }
                  return false
               }
         }

      let graphType = navigator.state.preferences.chartType.debug()

      let didTapChartTypeBarButton = input.didTapchartTypeBarButton
         .withLatestFrom(graphType)
         .map { $0.opposite }
         .do(onNext: { [weak self] chartType in
            self?.navigator.state.preferences.set(chartType: chartType)
            self?.navigator.state.preferences.save()
         })

      return .init(currencyPair: navigator.currencyPair,
                   watchlistButtonClicked: watchlistButtonClicked,
                   currencyDetail: currencyDetail.asDriver().filterNil(),
                   watchlistDetailData: watchlistDetailData,
                   historicalPriceResult: historicalPriceResult,
                   candleGraphData: candleGraphData,
                   lineGraphData: lineGraphData,
                   selectedPriceText: selectedPrice,
                   candleStickSelectedPriceText: candleStickSelectedPrice,
                   selectedDateText: selectedDate,
                   historicalPriceIsLoading: historicalPriceIsLoading,
                   currencyDetailResult: currencyDetailResult,
                   loadStateViewModel: loadStateViewModel,
                   price: price,
                   priceChangePctPriceChange: priceChangePctPriceChange,
                   didTapPriceAlert: didTapPriceAlert,
                   isUpdateAlert: isUpdateAlert,
                   graphType: graphType,
                   didTapChartTypeBarButton: didTapChartTypeBarButton)
   }
}
