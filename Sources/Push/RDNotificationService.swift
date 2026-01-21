//
//  RDNotificationService.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import UserNotifications

open class RDNotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    open override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        PushUNNotificationServiceExtensionHandler.didReceive(bestAttemptContent) { [weak self] content in
            self?.contentHandler?(content)
        }
    }
    
    open override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
