//
//  SettingsViewModel.swift
//  App
//
//  Created by Kok Hong Choo on 20/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift
import StoreKit

final class SettingsViewModel: TransformableViewModelType, Navigable {
   weak var navigator: SettingsNavigatorType!

   init(navigator: SettingsNavigatorType) {
      self.navigator = navigator
   }

   struct Input {
      let settingSelectedObservable: Observable<SettingListData>
   }

   struct Output {
      let version: String
      let settingsData: Driver<[SettingListData]>
      let title: String
      let settingSelectedDriver: Driver<Void>
   }

   func transform(input: Input) -> Output {
      let title = "settings.title".localized()
      let version = Bundle.main.versionString
      let language = navigator.state.preferences.language
      let theme = navigator.state.preferences.theme

      let settingsData: Driver<[SettingListData]> = Driver.combineLatest(language, theme) { language, theme in
         let languageData = SettingListData.language(lang: language)
         let displayModeData = SettingListData.nightMode(mode: theme,
                                                         switchChanged: self.navigator.state.preferences.set)
         return [.termsAndCondition, .rate, languageData, displayModeData, .credits]
      }

      let settingSelectedDriver = input.settingSelectedObservable
         .do(onNext: { [weak self] settingListData in
            switch settingListData {
            case .termsAndCondition:
               self?.navigator.showTermsAndCondition()
            case .rate:
               AppStoreReviewHelper.navigateUserForReview()
            case .credits:
               self?.navigator.showCredits()
            default:
               break
            }
         })
         .void()
         .asDriver()

      return .init(version: version,
                   settingsData: settingsData,
                   title: title,
                   settingSelectedDriver: settingSelectedDriver)
   }
}
