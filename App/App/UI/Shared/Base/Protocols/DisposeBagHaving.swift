//
//  DisposeBagHaving.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

protocol DisposeBagHaving: class {
   var disposeBag: DisposeBag { get set }
}
