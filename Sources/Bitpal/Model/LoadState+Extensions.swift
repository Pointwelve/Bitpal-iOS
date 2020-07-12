//
//  LoadState.swift
//  App
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa

/// The current states presented on screen, note: may be multiple.
extension LoadState {
   enum Strategy {
      /// This strategy uses all inputs to determine the state of the screen.
      case `default`
      /// This strategy ignores all except the offline, and ready states.
      case offlineOnly
      /// This strategy ignores all except the loading, offline, and ready states.
      case web
      /// This strategy ignores all except the loading, and ready states.
      case staticWeb
      /// This strategy ignores all except the offline and ready states
      case offlineAndReady
      /// This strategy uses whatever is passed in, unless we are offline.
      case manual
      /// This strategy ignores all except the empty, and ready states.
      case empty
      /// This strategy ignores all except the offline, empty and ready state for watchlist.
      case watchlist
      /// This strategy ignores all except the offline, empty and ready state for alerts.
      case alerts
   }

   var title: String {
      if contains(.empty) {
         return "empty.view.title".localized()
      } else if contains(.offline) {
         return "offline.view.title".localized()
      } else if contains(.error) {
         return "error.sorry.title".localized()
      } else if contains(.loading) {
         return "loading.title".localized()
      } else if contains(.emptyWatchlist) {
         return "empty.watchlist.title".localized()
      } else if contains(.emptyAlerts) {
         return "empty.alerts.title".localized()
      } else if contains(.noNotificationPermission) {
         return "notification.noPermission.title".localized()
      } else {
         return ""
      }
   }

   var message: String {
      if contains(.empty) {
         return "empty.view.message".localized()
      } else if contains(.offline) {
         return "offline.view.message".localized()
      } else if contains(.error) {
         return "error.sorry.message".localized()
      } else if contains(.loading) {
         return "loading.message".localized()
      } else if contains(.emptyWatchlist) {
         return "empty.watchlist.message".localized()
      } else if contains(.emptyAlerts) {
         return "empty.alerts.message".localized()
      } else if contains(.noNotificationPermission) {
         return "notification.noPermission.message".localized()
      } else {
         return ""
      }
   }

   var buttonTitle: String? {
      if contains(.noNotificationPermission) {
         return "notification.noPermission.action.title".localized()
      }

      return nil
   }

   func debug() {
      if contains(.offline) {
         debugPrint("Offline")
      }
      if contains(.loading) {
         debugPrint("Loading")
      }
      if contains(.ready) {
         debugPrint("Ready")
      }
      if contains(.empty) {
         debugPrint("Empty")
      }
      if contains(.expired) {
         debugPrint("Expired")
      }
      if contains(.pageAvailable) {
         debugPrint("Page Available")
      }
      if contains(.pageError) {
         debugPrint("Page Error")
      }
      if contains(.pageLoading) {
         debugPrint("Page Loading")
      }
      if contains(.emptyWatchlist) {
         debugPrint("Empty Watchlist")
      }
   }
}

extension LoadState {
   /// Remove any state information that is conflicting or does not adhere to the strategy.

   // swiftlint:disable cyclomatic_complexity
   func prepareForDisplay(strategy: Strategy) -> LoadState {
      switch strategy {
      case .manual:
         // This strategy uses whatever is passed in, unless we are offline.
         if contains(.ready) {
            return self
         } else if contains(.offline) {
            return [.offline]
         } else {
            return self
         }

      case .offlineOnly:
         // This strategy ignores all other information
         if contains(.offline) {
            return [.offline]
         } else {
            return [.ready]
         }

      case .web:
         // This strategy ignores all other information
         if contains(.loading) {
            if contains(.offline) {
               return [.offline]
            } else {
               return [.loading]
            }
         } else if contains(.error) {
            if contains(.offline) {
               return [.offline]
            } else {
               return [.error]
            }
         } else {
            return [.ready]
         }

      case .staticWeb:
         // This strategy ignores all other information
         if contains(.loading) {
            return [.loading]
         } else if contains(.error) {
            return [.error]
         } else {
            return [.ready]
         }

      case .offlineAndReady:
         var display: LoadState = []

         if contains(.offline) {
            display.formUnion(.offline)
         }

         if contains(.ready) {
            display.formUnion(.ready)
         }

         return display

      case .empty:
         // This strategy ignores all other information
         if contains(.empty) {
            return [.empty]
         } else {
            return [.ready]
         }

      case .watchlist:
         if contains(.offline) {
            return [.offline]
         } else if contains(.error) {
            return [.error]
         } else if contains(.loading) {
            return [.loading]
         } else if contains(.emptyWatchlist) {
            return [.emptyWatchlist]
         } else {
            return [.ready]
         }

      case .alerts:
         if contains(.offline) {
            return [.offline]
         } else if contains(.error) {
            return [.error]
         } else if contains(.loading) {
            return [.loading]
         } else if contains(.emptyAlerts) {
            return [.emptyAlerts]
         } else if contains(.noNotificationPermission) {
            return [.noNotificationPermission]
         } else {
            return [.ready]
         }

      default:
         var display: LoadState = []

         if contains(.loading), !contains(.offline) {
            display.formUnion(.loading)
         }

         if contains(.ready) {
            display.formUnion(.ready)
            return display
         }

         if !display.contains(.loading) {
            // Empty state can be negated by offline or error states
            if contains(.offline) {
               display.formUnion(.offline)
            } else if contains(.error) {
               display.formUnion(.error)
            } else {
               display.formUnion(.empty)
            }
         }

         return display
      }
   }
}

// MARK: - Helpers

extension LoadState {
   mutating func setEmpty() {
      // Negate loading, ready and expired states
      subtract([.ready, .loading, .expired])
      formUnion(.empty)
   }

   mutating func setReady() {
      // Negate loading, error, expired and empty states
      subtract([.loading, .error, .expired, .empty])
      formUnion(.ready)
   }

   mutating func setError() {
      // Negate loading
      subtract(.loading)
      formUnion(.error)
   }

   mutating func setOffline(_ isOffline: Bool) {
      if isOffline {
         formUnion(.offline)
      } else {
         subtract(.offline)
      }
   }

   mutating func setLoading(_ isLoading: Bool) {
      if isLoading {
         // Loading may appear over the top of other states
         // so don't negate anything here.
         formUnion(.loading)
      } else {
         subtract(.loading)
      }
   }

   mutating func setExpired(_ expired: Bool) {
      if expired {
         // Negate empty, loading, ready states
         subtract([.empty, .loading, .ready])
         formUnion(.expired)
      } else {
         subtract(.expired)
      }
   }

   mutating func setUnready() {
      subtract(.ready)
   }
}
