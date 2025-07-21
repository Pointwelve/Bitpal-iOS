//
//  UnsubscribeStreamRepository.swift
//  Data
//
//  Created by Kok Hong Choo on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

public typealias UnsubscribeStreamRepositoryType = Readable

public class UnsubscribeStreamRepository: UnsubscribeStreamRepositoryType {
   public typealias Key = Void
   public typealias Value = Void

   fileprivate let socketClient: SocketClient

   init(socketClient: SocketClient) {
      self.socketClient = socketClient
   }
}

extension UnsubscribeStreamRepository {
   public func read() -> Observable<Void> {
      return Observable.create { [weak self] observer in
         self?.socketClient.disconnect()
         observer.onNext(())
         observer.onCompleted()

         return Disposables.create()
      }
   }
}
