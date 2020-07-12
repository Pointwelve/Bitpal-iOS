//
//  UITableView+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension UITableView {
   func hideEmptyCells() {
      tableFooterView = UIView(frame: .zero)
   }

   /// Dequeue cell of a specified type.
   ///
   /// - Parameters:
   ///   - type: Type to return.
   ///   - indexPath: IndexPath of the cell.
   ///   - identifier: Optional identifier. If nil a description of the Type will be used.
   /// - Returns: Cell of specified type.
   func dequeueCell<T>(of type: T.Type, at indexPath: IndexPath, with identifier: String? = nil) -> T {
      // swiftlint:disable force_cast
      return dequeueReusableCell(withIdentifier: identifier ?? String(describing: type.self),
                                 for: indexPath) as! T
   }

   /// Register cell for dequeuing.
   ///
   /// - Parameters:
   ///   - type: Type to register.
   ///   - identifier: Optional identifier. If nil a description of the Type will be used.
   func registerCell<T>(of type: T.Type, with identifier: String? = nil) {
      register(type.self as? AnyClass, forCellReuseIdentifier: identifier ?? String(describing: type.self))
   }
}
