//
//  AppearableNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol AppearableNavigatorType: NavigatorType, Appearable {
   /// Whether VC has become visible.
   var didBecomeVisible: Driver<Bool>! { get set }
}
