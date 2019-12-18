//
//  RxReachabilityProvider.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import class Alamofire.NetworkReachabilityManager
import RxCocoa
import RxSwift

// MARK: - Reachability Status extension

extension ReachabilityStatus {
   var isReachable: Bool {
      switch self {
      case .reachable:
         return true
      case .notReachable, .unknown:
         return false
      }
   }
}

final class RxReachabilityProvider: ReachabilityProvider {
   var retryInterval: Int = 120

   /// Reachability service error
   ///
   /// - failedToCreate: Failing to create reachability service due to port unavailability

   enum ReachabilityServiceError: Error {
      case failedToCreate
   }

   /// Create background scheduler to update reachability variable on notifications.
   private lazy var backgroundScheduler: ImmediateSchedulerType = {
      ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "reachability.wificheck"))
   }()

   private let disposeBag = DisposeBag()

   /// Reachability manager to bind to once successfully intialised
   private let _reachabilityManager = BehaviorRelay<NetworkReachabilityManager?>(value: nil)

   /// Reachability status
   private let _isReachable = BehaviorSubject<Bool>(value: true)

   /// Reachability status to be observed on
   public var isOnline: Observable<Bool> {
      return _isReachable.catchErrorJustReturn(true)
   }

   init() {
      Observable<NetworkReachabilityManager>.create { observer in
         guard let reachabilityRef = NetworkReachabilityManager() else {
            observer.on(.error(ReachabilityServiceError.failedToCreate))
            return Disposables.create()
         }

         observer.on(.next(reachabilityRef))
         observer.on(.completed)

         return Disposables.create()

      }.retryOnError(every: retryInterval)
         .bind(to: _reachabilityManager)
         .disposed(by: disposeBag)

      _reachabilityManager
         .asObservable()
         .subscribeOn(backgroundScheduler)
         .subscribe(onNext: { manager in
            if let manager = manager {
               self._isReachable.on(.next(manager.isReachable))
               manager.listener = {
                  reachability in
                  self._isReachable.on(.next(reachability.isReachable))
               }
               manager.startListening()
            }
         })
         .disposed(by: disposeBag)
   }
}
