//
//  DispatchQueue+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

func wait(_ seconds: TimeInterval = 1.0, queue: DispatchQueue = .main, block: @escaping () -> Void) {
   queue.asyncAfter(deadline: .now() + seconds, execute: block)
}
