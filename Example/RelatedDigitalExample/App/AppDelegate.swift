//
//  AppDelegate.swift
//  RelatedDigitalExample
//
//  Boots the SDK and owns everything that has to live on UIApplicationDelegate:
//  remote-notification registration, push payload handoff and action buttons.
//

import RelatedDigitalIOS
import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let config = AppConfig.shared

        // The test environment overrides organization/profile ids inside the SDK,
        // so it has to be applied before `initialize`.
        if config.useTestEnvironment {
            UrlConstant.shared.setTest()
        }

        RelatedDigital.initialize(
            organizationId: config.organizationId,
            profileId: config.profileId,
            dataSource: config.dataSource,
            launchOptions: launchOptions,
            askLocationPermmissionAtStart: config.askLocationPermissionAtStart
        )

        RelatedDigital.enablePushNotifications(
            appAlias: config.appAlias,
            launchOptions: launchOptions,
            appGroupsKey: config.appGroupsKey.isEmpty ? nil : config.appGroupsKey,
            deliveredBadge: true
        )

        RelatedDigital.loggingEnabled = config.loggingEnabled
        RelatedDigital.inAppNotificationsEnabled = config.inAppNotificationsEnabled
        RelatedDigital.geofenceEnabled = config.geofenceEnabled

        UNUserNotificationCenter.current().delegate = self
        TargetingDelegateHub.shared.register()

        MainActor.assumeIsolated {
            config.markInitialized()
            RDLog.info("RelatedDigital.initialize", detail: EventLog.render([
                "organizationId": config.organizationId,
                "profileId": config.profileId,
                "dataSource": config.dataSource,
                "appAlias": config.appAlias,
                "environment": config.environment.displayName,
                "host": config.environment.host
            ]))
            PushCenter.shared.refreshAuthorizationStatus()
            PushCenter.shared.refreshToken()
        }

        observeInAppLinks()
        return true
    }

    // MARK: - Remote notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        RelatedDigital.registerToken(tokenData: deviceToken)
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        MainActor.assumeIsolated {
            RDLog.result("Device token registered", channel: .push, detail: token)
            PushCenter.shared.refreshToken()
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        MainActor.assumeIsolated {
            RDLog.failure("Remote notification registration failed",
                          channel: .push, detail: error.localizedDescription)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        RelatedDigital.handlePush(pushDictionary: userInfo)
        MainActor.assumeIsolated {
            RDLog.result("Silent push received", channel: .push, detail: userInfo.prettyPrinted)
        }
        completionHandler(.newData)
    }

    // MARK: - In-app links

    /// The SDK broadcasts in-app notification links over `NotificationCenter`.
    private func observeInAppLinks() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("InAppLink"), object: nil, queue: .main
        ) { notification in
            let link = notification.userInfo?["link"] as? String
            MainActor.assumeIsolated {
                RDLog.result("In-app link tapped", channel: .targeting, detail: link)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        MainActor.assumeIsolated {
            RDLog.result("Notification presented in foreground",
                         channel: .push, detail: userInfo.prettyPrinted)
        }
        completionHandler([.banner, .list, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        RelatedDigital.handlePush(pushDictionary: userInfo)
        RelatedDigital.handlePushWithActionButtons(response: response, type: self)
        MainActor.assumeIsolated {
            RDLog.result("Notification opened", channel: .push, detail: userInfo.prettyPrinted)
            PushCenter.shared.refreshAuthorizationStatus()
        }
        completionHandler()
    }
}

// MARK: - PushAction

extension AppDelegate: PushAction {

    func actionButtonClicked(identifier: String, url: String) {
        MainActor.assumeIsolated {
            RDLog.result("Push action button tapped", channel: .push,
                         detail: "identifier = \(identifier)\nurl = \(url)")
        }
    }
}

// MARK: - Helpers

extension Dictionary where Key == AnyHashable, Value == Any {

    /// Best-effort JSON rendering of a push payload for the console.
    var prettyPrinted: String {
        if JSONSerialization.isValidJSONObject(self),
           let data = try? JSONSerialization.data(withJSONObject: self,
                                                  options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return map { "\($0.key) = \($0.value)" }.sorted().joined(separator: "\n")
    }
}
