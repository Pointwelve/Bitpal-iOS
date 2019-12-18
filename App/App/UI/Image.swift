//
//  Image.swift
//  SEED
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Tigerspike. All rights reserved.
//

import UIKit

protocol ImageType {
   var resource: UIImage { get }
   var resourceWhileSelected: UIImage? { get }
}
