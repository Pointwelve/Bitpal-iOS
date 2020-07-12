//
//  UpdateProvider.swift
//  App
//
//  Created by Ryne Cheow on 8/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import Siren

final class UpdateProvider: NSObject {
   enum Frequency {
      case daily
      case now
   }

   private let siren = Siren.shared

   override init() {
      super.init()

      siren.rulesManager = RulesManager(majorUpdateRules: .annoying,
                                        minorUpdateRules: .critical,
                                        patchUpdateRules: .default,
                                        revisionUpdateRules: .relaxed)
   }

   func performCheck(frequency: Frequency = .now) {
      siren.wail(performCheck: PerformCheck.onDemand) { result in
         switch result {
         case let .success(value):
            switch value.alertAction {
            case .skip:
               AnalyticsProvider.log(event: "Version Update Check", metadata: [
                  "user_action": "Skip",
                  "current_version": Bundle.main.versionString
               ])
            case .appStore:
               AnalyticsProvider.log(event: "Version Update Check", metadata: [
                  "user_action": "Launched App Store",
                  "current_version": Bundle.main.versionString
               ])
            case .nextTime:
               AnalyticsProvider.log(event: "Version Update Check", metadata: [
                  "user_action": "Cancel",
                  "current_version": Bundle.main.versionString
               ])
            default:
               break
            }
         default:
            break
         }
      }
   }
}
