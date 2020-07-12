//
//  SharedServiceProvider.swift
//  App
//
//  Created by James Lai on 31/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

protocol ServiceProviderType {
   var configuration: Observable<ConfigurationUseCaseCoordinator> { get }
   var isOnline: Driver<Bool> { get }
}
