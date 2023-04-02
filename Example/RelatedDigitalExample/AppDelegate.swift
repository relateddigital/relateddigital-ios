//
//  AppDelegate.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import RelatedDigitalIOS
import UIKit
import UserNotifications

var relatedDigitalProfile = RelatedDigitalProfile()

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var isRelatedInit = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if urlConstant.shared.getTestWithLocalData() {
            urlConstant.shared.setTest()
        }
        RelatedDigital.initialize(organizationId: relatedDigitalProfile.organizationId, profileId: relatedDigitalProfile.profileId, dataSource: relatedDigitalProfile.dataSource, launchOptions: launchOptions, askLocationPermmissionAtStart: true)
        RelatedDigital.enablePushNotifications(appAlias: "RDIOSExample", launchOptions: launchOptions, appGroupsKey: "group.com.relateddigital.RelatedDigitalExample.relateddigital", deliveredBadge: true)
        UNUserNotificationCenter.current().delegate = self
        RelatedDigital.loggingEnabled = true
        if #available(iOS 13, *) {
            // handle push for iOS 13 and later in sceneDelegate
        } else if let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] {
            RelatedDigital.handlePush(pushDictionary: userInfo)
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = SelectViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    func getTabBarController() -> RelatedDigitalTabBarController {
        return RelatedDigitalTabBarController()
    }

    func getPushViewController() -> PushViewController {
        return PushViewController()
    }

    func getHomeViewController() -> HomeViewController {
        return HomeViewController()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        RelatedDigital.registerToken(tokenData: deviceToken)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        RelatedDigital.handlePush(pushDictionary: userInfo)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RelatedDigital.handlePush(pushDictionary: userInfo)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        RelatedDigital.handlePush(pushDictionary: response.notification.request.content.userInfo)
        completionHandler()
    }
}
