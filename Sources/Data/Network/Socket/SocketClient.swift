//
//  SocketClient.swift
//  Data
//
//  Created by Ryne Cheow on 30/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift
import SocketIO

class SocketClient: APIClientType {
   typealias GetSocketHostAction = () -> Observable<String>

   private enum SocketEvent: String {
      case m
      case subAdd = "SubAdd"
      case subRemove = "SubRemove"
   }

   private enum Config {
      static let waitInSeconds = 5
      static let reconnectAttempts = 99
   }

   private let disposeBag = DisposeBag()
   private let sslCertificateData = BehaviorRelay<Data?>(value: nil)
   private let baseUrl = BehaviorRelay<String>(value: "")
   private var socketManager: SocketManager?
   private var subscriptions: [String: Any]?

   init(getSocketAction: @escaping GetSocketHostAction,
        onAppEnteredBackground: Observable<Void>,
        onAppEnteredForeground: Observable<Void>) {
      getSocketAction()
         .bind(to: baseUrl)
         .disposed(by: disposeBag)

      onAppEnteredBackground.subscribe(onNext: { [weak self] in
         self?.disconnect()
      }).disposed(by: disposeBag)
   }

   private func url() -> URL {
      return URL(string: baseUrl.value)!
   }

   private func client(for route: Router) -> SocketManager {
      let manager = SocketManager(socketURL: url(),
                                  config: [
                                     .log(false), .secure(true),
                                     .reconnectWait(Config.waitInSeconds),
                                     .reconnectAttempts(Config.reconnectAttempts)
                                  ])
      return manager
   }

   func disconnect() {
      socketManager?.disconnect()
      socketManager = nil
      subscriptions = nil
   }

   func executeRequest(for router: Router) -> Observable<String> {
      let manager = socketManager ?? client(for: router)
      let sc = manager.defaultSocket

      if socketManager == nil {
         socketManager = manager

         sc.connect()
      }

      switch sc.status {
      case .connected:
         var subscriptions = self.subscriptions ?? [String: Any]()
         let parameters = router.parameters ?? [String: Any]()

         if let subs = subscriptions["subs"] as? [String],
            let paramSubs = parameters["subs"] as? [String] {
            subscriptions["subs"] = subs.filter { !paramSubs.contains($0) }
         }

         sc.emit(SocketEvent.subRemove.rawValue, subscriptions)
         sc.emit(SocketEvent.subAdd.rawValue, parameters)

         self.subscriptions = parameters

      case .connecting, .notConnected, .disconnected:
         sc.on(clientEvent: .connect) { _, _ in
            debugPrint("🚨Socket connected!🚨")

            var subscriptions = self.subscriptions ?? [String: Any]()
            let parameters = router.parameters ?? [String: Any]()

            if let subs = subscriptions["subs"] as? [String],
               let paramSubs = parameters["subs"] as? [String] {
               subscriptions["subs"] = subs.filter { !paramSubs.contains($0) }
            }

            sc.emit(SocketEvent.subRemove.rawValue, subscriptions)
            sc.emit(SocketEvent.subAdd.rawValue, parameters)

            self.subscriptions = parameters
         }
      }

      return sc.rx.on(SocketEvent.m.rawValue)
         .map { ($0 as? [String])?.first }
         .filterNil()
   }
}
