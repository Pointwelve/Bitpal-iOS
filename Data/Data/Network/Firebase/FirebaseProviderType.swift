//
//  FirebaseProviderType.swift
//  Data
//
//  Created by James Lai on 21/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol FirebaseDatabaseProviderType {
   func read(paths: [String]) -> Observable<Any>

   func write(paths: [String], params: [String: Any]) -> Observable<Any>

   func write(paths: [String], params: [Any]) -> Observable<Any>
}

public protocol FirebaseAuthProviderType {
   var userId: Observable<String> { get }
}
