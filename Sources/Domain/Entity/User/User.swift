//
//  User.swift
//  Domain
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public protocol UserType {
   var refreshToken: String? { get }

   var userId: String { get }
}
