//
//  AlertsTableViewModel.swift
//  App
//
//  Created by James Lai on 10/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class AlertsTableViewModel: TransformableViewModelType {
   struct Input {
      let alert: Alert
      let didTapAlertSwicth: Driver<Bool>
      let updateAlertApi: (Alert) -> Driver<Bool>
   }

   struct Output {
      let alert: Driver<Alert>
      let didTapAlertSwitch: Driver<Bool>
   }

   func transform(input: Input) -> Output {
      let alert = BehaviorRelay<Alert>(value: input.alert)
      let alertDriver = alert.asDriver()

      let didTapAlertSwitch = input.didTapAlertSwicth
         .withLatestFrom(alertDriver) { ($0, $1) }
         .filter { $0.0 != $0.1.isEnabled }
         .do(onNext: { isEnabled, currentAlert in
            alert.accept(Alert(id: currentAlert.id,
                               base: currentAlert.base,
                               quote: currentAlert.quote,
                               exchange: currentAlert.exchange,
                               comparison: currentAlert.comparison,
                               reference: currentAlert.reference,
                               isEnabled: isEnabled))
         })
         .flatMapLatest { _ in input.updateAlertApi(alert.value) }

      return Output(alert: alertDriver,
                    didTapAlertSwitch: didTapAlertSwitch)
   }
}
