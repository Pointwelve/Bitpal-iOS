//
//  CreatePriceAlertViewModel.swift
//  App
//
//  Created by James Lai on 5/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class CreatePriceAlertViewModel: TransformableViewModelType, Navigable {
   weak var navigator: CreatePriceAlertNavigatorType!

   init(navigator: CreatePriceAlertNavigatorType) {
      self.navigator = navigator
   }

   struct Input {
      let isLesserButtonSelected: Driver<Bool>
      let didTapCloseButton: Driver<Void>
      let didSelectLesserButton: Driver<Void>
      let didSelectGreaterButton: Driver<Void>
      let didPriceChanged: Driver<String?>
      let viewDidTap: Driver<Void>
      let validPrice: Driver<String?>
      let didTapCreate: Driver<Void>
   }

   struct Output {
      let didTapCloseButton: Driver<Void>
      let didSelectLesserButton: Driver<Void>
      let didSelectGreaterButton: Driver<Void>
      let createAlertData: Driver<CreateAlertUIData>
      let alertMessagePriceText: Driver<String>
      let viewDidTap: Driver<Void>
      let validPriceText: Driver<String>
      let didTapCreate: Driver<Void>
      let isLoading: Driver<Bool>
      let loadingIndicatorState: Driver<LoadingIndicatorState>
   }

   // swiftlint:disable cyclomatic_complexity
   func transform(input: Input) -> Output {
      let didTapCloseButton = input.didTapCloseButton
         .do(onNext: { [weak self] in
            self?.navigator.dismissCreatePriceAlert()
         })

      let didPriceChanged = input.didPriceChanged
         .filterNil()

      let validPriceText = didPriceChanged.withLatestFrom(input.validPrice) { ($0, $1) }
         .map { [weak self] enteredPrice, latestValidPrice -> String? in
            guard let `self` = self,
               enteredPrice != latestValidPrice else {
               return latestValidPrice
            }

            let currentPrice = self.navigator.currencyPairDetail.price.formatUsingSignificantDigits()
            let maxLength = currentPrice.count + 2
            let maxSignificant = { () -> Int in
               let split = currentPrice.components(separatedBy: ".")
               if split.count == 2 {
                  return split[1].count + 2
               }

               return 2
            }()

            return enteredPrice.format(latestValidPrice, maxLength: maxLength, maxSignificant: maxSignificant)
         }
         .filterNil()

      let alertComparison = input.isLesserButtonSelected
         .map { $0 ? AlertComparison.lessThanOrEqual : AlertComparison.greaterThanOrEqual }

      let priceSymbol = navigator.currencyPairDetail.toDisplaySymbol

      let alertMessagePriceText = Driver.combineLatest(alertComparison,
                                                       validPriceText.distinctUntilChanged())
         .map { comparison, price -> String in
            let priceText = "\(priceSymbol)\(price)"
            return comparison == .greaterThanOrEqual
               ? "priceAlert.alertMessage.greaterThanOrEqual"
               .localizedFormat(arguments: priceText)
               : "priceAlert.alertMessage.lessThanOrEqual"
               .localizedFormat(arguments: priceText)
         }

      let createAlertData = navigator.state.preferences.serviceProvider.repository.alert
         .alerts()
         .getResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.alertList }
         .map { [weak self] alertList -> CreateAlertUIData in
            guard let currencyDetail = self?.navigator.currencyPairDetail else {
               return CreateAlertUIData.emptyData
            }

            if let alertList = alertList {
               for alert in alertList.alerts
                  where alert.pair == "\(currencyDetail.fromCurrency)_\(currencyDetail.toCurrency)" &&
                  alert.exchange == currencyDetail.exchange {
                  return CreateAlertUIData(id: alert.id,
                                           quoteSymbol: currencyDetail.toDisplaySymbol,
                                           exchange: currencyDetail.exchange,
                                           comparison: alert.comparison,
                                           reference: alert.reference,
                                           isEnabled: alert.isEnabled,
                                           isUpdate: true)
               }
            }

            let decimal = Decimal(string: currencyDetail.price.formatUsingSignificantDigits())
               ?? Decimal(currencyDetail.price)
            return CreateAlertUIData(quoteSymbol: currencyDetail.toDisplaySymbol,
                                     exchange: currencyDetail.exchange,
                                     reference: decimal)
         }

      let requestData = Driver.combineLatest(alertComparison, validPriceText, createAlertData) { ($0, $1, $2) }

      let prepareDidTapCreate = input.didTapCreate
         .withLatestFrom(requestData)
         .flatMapLatest { [weak self] comparison, price, createAlertUIData -> Driver<(Bool, Bool)> in
            guard let `self` = self,
               let currency = self.navigator.currencyPairDetail,
               let reference = Decimal(string: price) else {
               return .just((false, false))
            }

            // Update flow
            if createAlertUIData.isUpdate {
               guard let id = createAlertUIData.id else {
                  return .just((false, false))
               }

               let alert = Alert(id: id,
                                 base: currency.fromCurrency,
                                 quote: currency.toCurrency,
                                 exchange: currency.exchange,
                                 comparison: comparison,
                                 reference: reference,
                                 isEnabled: true)

               return self.navigator.state.preferences.serviceProvider.repository
                  .alert
                  .updateAlert(request: alert)
                  .updateResult()
                  .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
                  .map { ($0.hasContent, $0.isLoading) }
                  .do(onNext: { hasContent, _ in
                     if hasContent {
                        AnalyticsProvider.log(event: "Update Alert", metadata: alert.analyticsMetadata)
                     }
                  })
            }

            let request = CreateAlertRequest(base: currency.fromCurrency,
                                             quote: currency.toCurrency,
                                             exchange: currency.exchange,
                                             comparison: comparison,
                                             reference: reference,
                                             isEnabled: true)

            return self.navigator.state.preferences.serviceProvider.repository
               .alert
               .createAlert(request: request)
               .updateResult()
               .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
               .map { ($0.hasContent, $0.isLoading) }
               .do(onNext: { hasContent, _ in
                  if hasContent {
                     AnalyticsProvider.log(event: "Create Alert", metadata: request.analyticsMetadata)
                  }
               })
         }

      let didTapCreate = prepareDidTapCreate
         .filter { $0.0 }
         .void()

      let isLoading = prepareDidTapCreate
         .map { $0.1 }

      let finishCreateAlert = { [weak self] in
         guard let `self` = self else {
            return
         }

         self.navigator.dismissCreatePriceAlert()
      }

      let loadingIndicatorState: Driver<LoadingIndicatorState> =
         isLoading.map { $0 ? .loading : .dismiss(completion: finishCreateAlert) }

      return .init(didTapCloseButton: didTapCloseButton,
                   didSelectLesserButton: input.didSelectLesserButton,
                   didSelectGreaterButton: input.didSelectGreaterButton,
                   createAlertData: createAlertData,
                   alertMessagePriceText: alertMessagePriceText,
                   viewDidTap: input.viewDidTap,
                   validPriceText: validPriceText,
                   didTapCreate: didTapCreate,
                   isLoading: isLoading,
                   loadingIndicatorState: loadingIndicatorState)
   }
}
