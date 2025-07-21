//
//  ReachabilityProvider.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import class Alamofire.NetworkReachabilityManager
import RxSwift

typealias ReachabilityStatus = NetworkReachabilityManager.NetworkReachabilityStatus

/// Network reachability service adapted for Reactive extensions.

protocol ReachabilityProvider {
   /// Retry interval
   var retryInterval: Int { get }

   /// Reachability status observable sequence.
   var isOnline: Observable<Bool> { get }
}
