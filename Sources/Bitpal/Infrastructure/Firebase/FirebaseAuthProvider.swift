//
//  FirebaseAuthProvider.swift
//  App
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Data
import Domain
import FirebaseAuth
import Foundation
import RxSwift

final class FirebaseAuthProvider: FirebaseAuthProviderType {
   private let auth = Auth.auth()

   public func userId() -> Observable<String> {
      return Observable.just(auth.currentUser)
         .filterNil()
         .map { $0.uid }
         .share(replay: 1)
   }

   func authenticateAnonymously() -> Observable<UserType> {
      return Observable.deferred {
         Observable.create { observer in
            self.auth.signInAnonymously { result, error in
               if let error = error {
                  observer.on(.error(error))
                  return
               }

               if let result = result {
                  observer.on(.next(result.user))
               }
            }
            return Disposables.create()
         }
      }
   }

   func authenticate(with token: AuthenticationToken) -> Observable<UserType> {
      return Observable.deferred {
         Observable.create { observer in
            self.auth.signIn(withCustomToken: token.token, completion: { result, error in
               if let error = error {
                  observer.on(.error(error))
                  return
               }

               if let result = result {
                  observer.on(.next(result.user))
                  return
               }
            })
            return Disposables.create()
         }
      }
   }

   func authenticationToken() -> Observable<String> {
      return Observable.deferred {
         Observable.create { observer in
            guard let user = self.auth.currentUser else {
               observer.on(.error(FirebaseError.notAuthenticated))

               return Disposables.create()
            }
            user.getIDTokenForcingRefresh(false, completion: { token, error in
               if let error = error {
                  observer.on(.error(error))
                  return
               }

               if let token = token {
                  observer.on(.next(token))
                  return
               }
            })
            return Disposables.create()
         }
      }
   }
}

extension User: UserType {
   public var userId: String {
      return uid
   }
}
