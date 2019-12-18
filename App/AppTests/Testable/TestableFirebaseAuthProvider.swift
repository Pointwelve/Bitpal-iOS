//
//  TestableFirebaseAuthProvider.swift
//  AppTests
//
//  Created by Kok Hong Choo on 30/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Data
import Domain
import Foundation
import RxSwift

class TestableFirebaseAuthProvider: FirebaseAuthProviderType {
   func userId() -> Observable<String> {
      return .empty()
   }

   func authenticateAnonymously() -> Observable<UserType> {
      return .empty()
   }

   func authenticate(with token: AuthenticationToken) -> Observable<UserType> {
      return .empty()
   }

   func authenticationToken() -> Observable<String> {
      return .empty()
   }
}
