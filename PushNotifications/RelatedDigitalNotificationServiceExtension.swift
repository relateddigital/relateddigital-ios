//
//  RelatedDigitalNotificationServiceExtension.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 12.07.2021.
//

import UserNotifications


@available(iOS 11.0, *)
public class RelatedDigitalNotificationServiceExtension: UNNotificationServiceExtension {
    
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    }

    public override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            
        }
    }
    
}
