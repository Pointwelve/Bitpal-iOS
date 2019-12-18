//
//  PreferencesData.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

struct PreferencesData: DataType, Equatable {
   let language: LanguageData?
   let theme: ThemeData?
   let databaseName: String?
   let installed: Bool
   let chartType: Int?

   init(language: LanguageData?, theme: ThemeData?, databaseName: String?, installed: Bool, chartType: Int?) {
      self.language = language
      self.theme = theme
      self.databaseName = databaseName
      self.installed = installed
      self.chartType = chartType
   }
}
