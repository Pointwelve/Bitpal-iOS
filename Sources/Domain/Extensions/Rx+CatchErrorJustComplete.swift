//
//  Rx+CatchErrorJustComplete.swift
//  Domain
//
//  Created by Ryne Cheow on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
   public func catchErrorJustComplete() -> Observable<Element> {
      return catchError { _ in .empty() }
   }
}
