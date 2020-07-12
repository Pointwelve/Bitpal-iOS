//
//  StreamDeserializable.swift
//  Data
//
//  Created by Ryne Cheow on 31/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol StreamDeserializable {
   // Convert from plain string stream data
   init(streamData: String) throws
}
