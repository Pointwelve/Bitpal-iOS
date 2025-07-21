//
//  SocketIO+Rx.swift
//  Data
//
//  Created by Ryne Cheow on 30/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift
import SocketIO

extension Reactive where Base: SocketIOClient {
   func on(_ event: String) -> Observable<Any> {
      return Observable.create { observer in
         let id = self.base.on(event) { items, _ in
            observer.onNext(items)
         }

         return Disposables.create {
            self.base.off(id: id)
         }
      }
   }

   var event: Observable<SocketAnyEvent> {
      return Observable.create { observer in
         self.base.onAny { event in
            observer.onNext(event)
         }

         return Disposables.create()
      }.share(replay: 1)
   }
}
