//
//  WeakRelationships.swift
//  Data
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// Children should weakly link back to their parents so they can be
/// cleaned up when all of their parent objects have been removed.
@objc public protocol ChildType: class {
   var parents: [ParentType] { get }
}

/// Parents should keep a record of their children in order to clean
/// up any orphaned children when a parent is removed.
@objc public protocol ParentType: class {
   var children: [ChildType] { get }
}
