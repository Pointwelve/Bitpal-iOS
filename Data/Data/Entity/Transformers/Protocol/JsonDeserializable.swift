//
//  JsonDeserializable.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol JsonDeserializable {
   /// Converts object from `JSON` to `Data` layer.
   init(json: Any) throws
}
