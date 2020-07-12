//
//  LoadState.swift
//  Domain
//
//  Created by Ryne Cheow on 14/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// The current states presented on screen, note: may be multiple.
/// State is returned with a Response object.

public struct LoadState: OptionSet {
   public let rawValue: Int

   public init(rawValue: Int) {
      self.rawValue = rawValue
   }

   /// Loading state, can be combined with other states.
   public static let loading = LoadState(rawValue: 1 << 0)
   /// Offline means we are offline and have no content to display and should display offline message.
   public static let offline = LoadState(rawValue: 1 << 1)
   /// Error means we were unable to retrieve content and should display error message.
   public static let error = LoadState(rawValue: 1 << 2)
   /// Empty means there is no more content to display, for paged states this means there are no more pages.
   public static let empty = LoadState(rawValue: 1 << 3)
   /// Ready means we have content to display.
   public static let ready = LoadState(rawValue: 1 << 4)
   /// Expired means the content we are displaying has expired and should be purged.
   public static let expired = LoadState(rawValue: 1 << 5)

   /// Another page of content is available.
   public static let pageAvailable = LoadState(rawValue: 1 << 6)
   /// Attempting to load a new page of data.
   public static let pageLoading = LoadState(rawValue: 1 << 7)
   /// Attempting to load a new page of data resulted in error.
   public static let pageError = LoadState(rawValue: 1 << 8)
   /// Attempting to load a new page resulted in expired root page, user should be notified and event should retry.
   public static let pageExpired = LoadState(rawValue: 1 << 9)
   /// Attempted to get another page but it was empty.
   public static let pageEmpty = LoadState(rawValue: 1 << 10)
   /// Empty watchlist
   public static let emptyWatchlist = LoadState(rawValue: 1 << 11)
   /// Empty price alerts
   public static let emptyAlerts = LoadState(rawValue: 1 << 12)
   /// No notification permision
   public static let noNotificationPermission = LoadState(rawValue: 1 << 13)
}
