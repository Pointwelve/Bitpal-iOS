//
//  DateFormat.swift
//  App
//
//  Created by Kok Hong Choo on 24/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

enum DateFormat {
   static let standardReadableDateFormat: DateFormatter = {
      let df = DateFormatter()
      df.dateFormat = "language.dateFormat.current".localized()
      df.locale = Locale.current
      return df
   }()
}
