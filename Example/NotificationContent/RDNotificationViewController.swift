//
//  RDNotificationViewController.swift
//  NotificationContent
//
//  Created by Umut Can Alparslan on 23.02.2022.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import RelatedDigitalIOS

@objc(RDNotificationViewController)
class RDNotificationViewController: UIViewController, UNNotificationContentExtension {
    
    let carouselView = PushNotificationCarousel.initView()
    var completion: ((_ url: URL?, _ bestAttemptContent: UNMutableNotificationContent?) -> Void)?
    
    var notificationRequestIdentifier = ""
    
    func didReceive(_ notification: UNNotification) {
        notificationRequestIdentifier = notification.request.identifier
        RelatedDigital.initialize(organizationId: "676D325830564761676D453D", profileId: "356467332F6533766975593D", dataSource: "visistore", launchOptions: nil)
        RelatedDigital.enablePushNotifications(appAlias: "RDIOSExample", launchOptions: nil, appGroupsKey: "group.com.relateddigital.RelatedDigitalExample.relateddigital")
        carouselView.didReceive(notification)
    }
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        carouselView.didReceive(response, completionHandler: completion)

    }
    override func loadView() {
        completion = { [weak self] url, bestAttemptContent in
            if let identifier = self?.notificationRequestIdentifier {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
                UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { notifications in
                    bestAttemptContent?.badge = NSNumber(value: notifications.count)
                })
            }
            if let url = url {
                if #available(iOSApplicationExtension 12.0, *) {
                    self?.extensionContext?.dismissNotificationContentExtension()
                }
                self?.extensionContext?.open(url)
            } else {
                if #available(iOSApplicationExtension 12.0, *) {
                    self?.extensionContext?.performNotificationDefaultAction()
                }
            }
        }
        carouselView.completion = completion
        carouselView.delegate = self
        self.view = carouselView
    }
}

/**
 Add if you want to track which carousel element has been selected
 */
extension RDNotificationViewController: PushCarouselDelegate {
    func selectedItem(_ element: RDPushMessage.Element) {
        // Add your work...
        print("Selected element is => \(element)")
    }
}
