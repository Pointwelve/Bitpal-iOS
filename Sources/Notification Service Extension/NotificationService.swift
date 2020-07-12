//
//  NotificationService.swift
//  Notification Service Extension
//
//  Created by Li Hao on 5/2/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
   private enum AlertKey: String {
      case baseCurrency
      case quoteCurrency
      case amount
   }

   var contentHandler: ((UNNotificationContent) -> Void)?
   var bestAttemptContent: UNMutableNotificationContent?

   override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
      self.contentHandler = contentHandler
      bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

      guard let bestAttemptContent = bestAttemptContent else {
         return
      }

      if let baseCurrency = bestAttemptContent.userInfo[AlertKey.baseCurrency.rawValue] as? String,
         let quoteCurrency = bestAttemptContent.userInfo[AlertKey.quoteCurrency.rawValue] as? String,
         let amount = bestAttemptContent.userInfo[AlertKey.amount.rawValue] as? String {
         bestAttemptContent.body = "alert.body".localizedFormat(arguments: "\(baseCurrency)", "\(amount)", "\(quoteCurrency)")
      }

      contentHandler(bestAttemptContent)
   }

   override func serviceExtensionTimeWillExpire() {
      // Called just before the extension will be terminated by the system.
      // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
      if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
         contentHandler(bestAttemptContent)
      }
   }
}
