//
//  AlertsViewModel.swift
//  App
//
//  Created by James Lai on 10/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class AlertsViewModel: TransformableViewModelType, Navigable {
   typealias Navigator = AlertsNavigatorType

   struct Input {
      let isRegisteredForRemoteNotifications: Driver<Bool>
      let noNotificationButtonAction: () -> Void
      let viewWillAppear: Driver<Void>
      let deleteAlert: Observable<IndexPath>
   }

   struct Output {
      let alerts: Driver<[Alert]>
      let viewWillAppear: Driver<Void>
      let deleteAlert: Driver<Void>
      let loadStateViewModel: LoadStateViewModel
      let updateAlertApi: (Alert) -> Driver<Bool>
      let isLoading: Driver<Bool>
      let loadingIndicatorState: Driver<LoadingIndicatorState>
   }

   var navigator: AlertsNavigatorType!

   private var priceAlerts: [Int] = [1]

   init(navigator: AlertsNavigatorType) {
      self.navigator = navigator
   }

   func transform(input: Input) -> Output {
      let alerts = BehaviorRelay<[Alert]?>(value: nil)
      let alertsDriver = alerts.asDriver().filterNil()

      let fetchAlerts = navigator.state.preferences.serviceProvider.repository.alert
         .alerts()
         .getResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.alertList?.alerts }
         .filterNil()
         .do(onNext: { alerts.accept($0) })

      let viewWillAppear = input.viewWillAppear
         .flatMapLatest { fetchAlerts }
         .void()

      let loadStateViewModel = LoadStateViewModel()

      let loadState = Driver.combineLatest(input.isRegisteredForRemoteNotifications, alertsDriver)
         .map { isRegisteredForRemoteNotifications, alertList -> LoadState in
            !isRegisteredForRemoteNotifications ? LoadState.noNotificationPermission
               : alertList.isEmpty ? LoadState.emptyAlerts : LoadState.ready
         }
      _ = loadStateViewModel.transform(input: .init(navigator: navigator,
                                                    strategy: .alerts,
                                                    loadState: loadState,
                                                    buttonAction: input.noNotificationButtonAction))
      let prepareDeleteApi = input.deleteAlert
         .withLatestFrom(alertsDriver) { ($0, $1) }
         .flatMapLatest { [weak self] indexPath, alertList -> Observable<(Result<DeleteAlertUseCaseCoordinator>, IndexPath?)> in
            guard let `self` = self,
               alertList.count > indexPath.row else {
               return .just((.failure(.error(UseCaseError.executionFailed)), nil))
            }

            let alert = alertList[indexPath.row]

            return self.navigator.state.preferences.serviceProvider.repository
               .alert.deleteAlert(request: alert.id)
               .deleteResult()
               .map { ($0, indexPath) }
               .do(onNext: { coordinator, _ in
                  if coordinator.hasContent {
                     AnalyticsProvider.log(event: "Delete Alert", metadata: alert.analyticsMetadata)
                  }
               })
         }
         .asDriver(onErrorJustReturn: (.failure(.error(UseCaseError.executionFailed)), nil))

      let deleteAlert = prepareDeleteApi
         .filter { $0.0.hasContent }

         .do(onNext: { _, indexPath in
            guard let indexPath = indexPath else { return }
            var current = alerts.value
            current?.remove(at: indexPath.row)
            alerts.accept(current)
         })
         .void()

      let updateAlertApi: (Alert) -> Driver<Bool> = { alert in
         self.navigator.state.preferences.serviceProvider.repository
            .alert.updateAlert(request: alert)
            .updateResult()
            .map { !$0.isLoading }
            .asDriver(onErrorJustReturn: false)
      }

      let isLoading: Driver<Bool> = prepareDeleteApi.map { $0.0.isLoading }

      let loadingIndicatorState: Driver<LoadingIndicatorState> =
         isLoading.map { $0 ? .loading : .dismiss(completion: {}) }

      return Output(alerts: alertsDriver,
                    viewWillAppear: viewWillAppear,
                    deleteAlert: deleteAlert,
                    loadStateViewModel: loadStateViewModel,
                    updateAlertApi: updateAlertApi,
                    isLoading: isLoading,
                    loadingIndicatorState: loadingIndicatorState)
   }
}
