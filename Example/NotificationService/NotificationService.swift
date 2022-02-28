//
//  NotificationService.swift
//  NotificationService
//
//  Created by Umut Can Alparslan on 23.02.2022.
//

import UserNotifications
import RelatedDigitalIOS

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        RelatedDigital.initialize(organizationId: "676D325830564761676D453D", profileId: "356467332F6533766975593D", dataSource: "visistore", launchOptions: nil)
        RelatedDigital.enablePushNotifications(appAlias: "RDIOSExample", launchOptions: nil, appGroupsKey: "group.com.relateddigital.RelatedDigitalExample.relateddigital")
        RDPush.didReceive(bestAttemptContent, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        guard let contentHandler = self.contentHandler else {
            return;
        }
        guard let bestAttemptContent = self.bestAttemptContent else {
            return;
        }
        contentHandler(bestAttemptContent)
    }
}
