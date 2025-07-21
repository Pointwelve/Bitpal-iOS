//
//  FirebaseProviderType.swift
//  Domain
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol FirebaseAuthProviderType {
   func userId() -> Observable<String>
   func authenticateAnonymously() -> Observable<UserType>
   func authenticate(with token: AuthenticationToken) -> Observable<UserType>
   func authenticationToken() -> Observable<String>
}
