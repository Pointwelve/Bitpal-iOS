//
//  FirebaseRouter.swift
//  Domain
//
//  Created by Kok Hong Choo on 18/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum FirebaseRouter: Router {
   case writeDict([String], [String: Any])
   case writeArray([String], [Any])
   case read([String])

   public var parameters: [String: Any]? {
      return nil
   }
}
