//
//  SettingsListData.swift
//  App
//
//  Created by Kok Hong Choo on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import FirebaseCrashlytics
import Domain

enum SettingListData {
   case termsAndCondition
   case language(lang: Language)
   case nightMode(mode: Theme, switchChanged: (Theme) -> Void)
   case rate
   case credits

   var navigable: Bool {
      switch self {
      case .termsAndCondition, .rate, .credits:
         return true
      default:
         return false
      }
   }

   var switchable: Bool {
      switch self {
      case .nightMode:
         return true
      default:
         return false
      }
   }

   var title: String {
      switch self {
      case .termsAndCondition:
         return "settings.termsAndPrivacy.title".localized()
      case .language:
         return "settings.language.title".localized()
      case .nightMode:
         return "settings.nightMode.title".localized()
      case .rate:
         return "settings.rate.title".localized()
      case .credits:
         return "Credits"
      }
   }

   var description: String {
      switch self {
      case .termsAndCondition:
         return ""
      case .language:
         return "language.current".localized()
      case let .nightMode(mode, _):
         return mode.name
      case .rate:
         return ""
      case .credits:
         return ""
      }
   }

   var switchValue: Bool {
      switch self {
      case let .nightMode(theme, _):
         return theme == Theme.dark
      default:
         return false
      }
   }

   func switchValueChanged(isOn: Bool) {
      switch self {
      case let .nightMode(_, switchChanged):
         let newTheme: Theme = isOn ? .dark : .light
         switchChanged(newTheme)

         AnalyticsProvider.log(event: "Toggled theme", metadata: newTheme.analyticsMetadata)
      default:
         break
      }
   }

   var accessibilityId: AccessibilityIdentifier {
      switch self {
      case .termsAndCondition:
         return .termsAndConditionCell
      case .language:
         return .languageCell
      case .nightMode:
         return .styleCell
      case .rate:
         return .rateCell
      case .credits:
         return .creditsCell
      }
   }
}
