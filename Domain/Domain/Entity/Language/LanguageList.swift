//
//  LanguageList.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct LanguageList: DomainType, Equatable {
   public let defaultLanguage: Language
   public let languages: [Language]

   public init(defaultLanguage: Language, languages: [Language]) {
      self.defaultLanguage = defaultLanguage
      self.languages = languages
   }
}
