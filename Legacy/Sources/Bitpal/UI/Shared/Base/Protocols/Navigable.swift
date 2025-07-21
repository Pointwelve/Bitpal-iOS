//
//  Navigable.swift
//  App
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol Navigable {
   associatedtype Navigator

   var navigator: Navigator! { get set }

   init(navigator: Navigator)
}
