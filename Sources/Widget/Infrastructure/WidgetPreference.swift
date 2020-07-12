//
//  WidgetPreference.swift
//  App
//
//  Created by Li Hao Lai on 30/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

protocol WidgetPreferenceType {
   /// Provider of services which contain use cases to execute.
   var serviceProvider: WidgetServiceProviderType { get }
}

class WidgetPreference: WidgetPreferenceType {
   let disposeBag = DisposeBag()
   let serviceProvider: WidgetServiceProviderType
   let isLoaded: Driver<Bool>

   private let loaded = BehaviorRelay<Bool>(value: false)
   private let coordinator: BehaviorRelay<WidgetPreferenceUseCaseCoordinator>

   init(serviceProvider: WidgetServiceProvider = .shared) {
      let initialPreferences = Preferences()
      self.serviceProvider = serviceProvider
      self.serviceProvider.sessionManager.refresh(with: initialPreferences.databaseName)

      coordinator = BehaviorRelay(value: serviceProvider.repository.preferences
         .preferences(existing: initialPreferences))
      isLoaded = loaded.asDriver().filter { $0 }

      observeCoordinatorChanges()
      read()
   }

   private func observeCoordinatorChanges() {
      coordinator.asDriver()
         .drive(onNext: { [weak self] newCoordinator in
            guard let `self` = self else {
               return
            }
            // If the coordinator indicates that localization is needed or the gender is nil (we are onboarding)
            // or we haven't initialized a service provider yet, lets create one using the coordinator.
            if self.loaded.value == false {
               self.serviceProvider.sessionManager.refresh(with: newCoordinator.preferences.databaseName)
               if !newCoordinator.preferences.databaseName.isEmpty, self.loaded.value == false {
                  self.loaded.accept(true)
               }
            }
         })
         .disposed(by: disposeBag)
   }

   private func read() {
      // Read stored value
      coordinator.value.readResult()
         .subscribe(onNext: { result in
            switch result {
            case .failure(.offline):
               break
            case let .failure(.error(error)):
               debugPrint("Failed to load preferences: \(error)")
            case let .content(.with(coordinator, _)):
               self.coordinator.accept(coordinator)
            default:
               break
            }
         })
         .disposed(by: disposeBag)
   }
}
