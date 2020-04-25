//
//  AppDelegate.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import FirebaseCrashlytics
import Data
import Domain
import Firebase
import FirebaseMessaging
import RxCocoa
import RxSwift
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
   var window: UIWindow?
   var navigator: AppNavigator?

   let disposeBag = DisposeBag()

   let updateProvider = UpdateProvider()

   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      FirebaseApp.configure()

      // Apply styling
      Style.applyProxy()
      updateProvider.performCheck()
      // Setup navigator
      window = UIWindow(frame: UIScreen.main.bounds)

      let preferences = AppPreferences()

      navigator = AppNavigator(state: .init(window: window!,
                                            preferences: preferences))

      navigator?.start()

      // For iOS 10 display notification (sent via APNS)
      let notificationCenter = UNUserNotificationCenter.current()
      notificationCenter.delegate = self
      notificationCenter.requestAuthorization(options: [.badge, .sound, .alert]) { _, _ in
         notificationCenter.getNotificationSettings { settings in
            debugPrint("Notification settings: \(settings)")

            AnalyticsProvider.log(event: "Registering push notification",
                                  metadata: ["Enabled Push": settings.authorizationStatus == .authorized])

            guard settings.authorizationStatus == .authorized else { return }
         }
      }
      UIApplication.shared.registerForRemoteNotifications()

      return true
   }

   func applicationWillResignActive(_ application: UIApplication) {}

   func applicationDidEnterBackground(_ application: UIApplication) {}

   func applicationWillEnterForeground(_ application: UIApplication) {}

   func applicationDidBecomeActive(_ application: UIApplication) {}

   func applicationWillTerminate(_ application: UIApplication) {}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
      let userInfo = response.notification.request.content.userInfo

      guard let deeplink = userInfo["deeplink"] as? String,
         let routeDef = RouteProvider.open(with: deeplink) else {
         return
      }

      navigator?.state.preferences.serviceProvider.routes.accept(routeDef)
   }

   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler:
                               @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .sound, .badge])
   }
}

extension AppDelegate {
   func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      // TODO: Send token to server, together with user identifier
      Messaging.messaging().apnsToken = deviceToken
      if let fcmToken = Messaging.messaging().fcmToken {
         debugPrint("FCM token: \(fcmToken)")
         navigator?.pushToken.accept(fcmToken)
      }
   }

   func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {}

   func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {}

   func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}

extension AppDelegate: MessagingDelegate {
   func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
      debugPrint("Refreshed FCM token: \(fcmToken)")
      navigator?.pushToken.accept(fcmToken)
   }

   func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
      debugPrint("Firebase registration token: \(remoteMessage)")
   }
}
