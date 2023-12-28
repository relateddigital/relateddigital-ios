//
//  PushUNNotificationServiceExtensionHandler.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation
import UIKit

class PushUNNotificationServiceExtensionHandler {
    
    public static func didReceive(_ bestAttemptContent: UNMutableNotificationContent?
                                  , withContentHandler contentHandler:  @escaping (UNNotificationContent) -> Void) {
        
        guard let userInfo = bestAttemptContent?.userInfo, let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) else { return }
        guard let pushDetail = try? JSONDecoder.init().decode(RDPushMessage.self, from: data) else { return }
        if #available(iOS 15.0, *) {
            bestAttemptContent?.interruptionLevel = .timeSensitive
        }
        
        PushUserDefaultsUtils.savePayload(payload: pushDetail)
        
        if let notifLoginId = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.notificationLoginIdKey) as? String,
           !notifLoginId.isEmpty {
            PushUserDefaultsUtils.savePayloadWithId(payload: pushDetail, notificationLoginID: notifLoginId)
        } else {
            PushUserDefaultsUtils.savePayload(payload: pushDetail)
        }
        
        if pushDetail.sendDeliver() {
            if let shared = RDPush.shared {
                shared.networkQueue.async {
                    RDPush.emDeliverHandler?.reportDeliver(message: pushDetail)
                }
            }
        }
        
        if pushDetail.isSilent() {
            contentHandler(UNNotificationContent())
            return
        }
        
        // Setup carousel buttons
        if pushDetail.aps?.category == "carousel" {
            UNUNC.current().setNotificationCategories(getCarouselActionCategorySet())
        } else if pushDetail.actions?.count ?? 0 > 0 {
            addActionButtons(pushDetail)
        }
        
        // Setup notification for image/video
        guard let modifiedBestAttemptContent = bestAttemptContent else { return }
        
        if let sound = pushDetail.aps?.sound, sound.count > 0 {
            modifiedBestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        }
        
        if pushDetail.pushType == "Image" || pushDetail.pushType == "Video",
           let attachmentMedia = pushDetail.mediaUrl, let mediaUrl = URL(string: attachmentMedia) {
            loadAttachments(mediaUrl: mediaUrl, modifiedBestAttemptContent: modifiedBestAttemptContent, withContentHandler: contentHandler)
        } else if pushDetail.pushType == "Text" && pushDetail.actions?.count ?? 0 > 0 {
            let attachmentMedia = pushDetail.mediaUrl
            let mediaUrl = URL(string: "https://google.com")!
             loadAttachments(mediaUrl: mediaUrl, modifiedBestAttemptContent: modifiedBestAttemptContent, withContentHandler: contentHandler)
            
        } else if pushDetail.pushType == "Text" {
            contentHandler(modifiedBestAttemptContent)
        }
    }
    
    @available(iOS 10.0, *)
    static func addActionButtons(_ detail: RDPushMessage) {
        let categoryIdentifier = detail.aps?.category ??  "action_button"
        if let buttons = detail.actions {
            var actionButtons: [UNNotificationAction] = []
            var index = 0
            for button in buttons {
                if #available(iOS 15.0, *) {
                    actionButtons.append(UNNotificationAction(identifier: "action_\(index)",
                                                              title: button.Title ?? "",
                                                              options: [.foreground],icon: UNNotificationActionIcon.init(systemImageName: "\(button.Icon ?? "")")))
                } else {
                    actionButtons.append(UNNotificationAction(identifier: "action_\(index)",
                                                              title: button.Title ?? "",
                                                              options: [.foreground]))
                }
                index+=1
            }
            let actionCategory = UNNotificationCategory(identifier: categoryIdentifier,
                                                        actions: actionButtons,
                                                        intentIdentifiers: [], options: [])

            UNUserNotificationCenter.current().setNotificationCategories([actionCategory])
        }
    }
    
    
    private func openLink() {
        if let url = URL(string: "") {
            UIApplication.shared.open(url)
        }
    }
    
    static func getCarouselActionCategorySet() -> Set<UNNotificationCategory>  {
        let categoryIdentifier = "carousel"
        let carouselNext = UNNotificationAction(identifier: "carousel.next", title: "▶", options: [])
        let carouselPrevious = UNNotificationAction(identifier: "carousel.previous", title: "◀", options: [])
        let carouselCategory = UNNotificationCategory(identifier: categoryIdentifier, actions: [carouselNext, carouselPrevious], intentIdentifiers: [], options: [])
        return [carouselCategory]
    }
    
    static func loadAttachments(mediaUrl: URL,
                                modifiedBestAttemptContent: UNMutableNotificationContent,
                                withContentHandler contentHandler:  @escaping (UNNotificationContent) -> Void) {
        let session = URLSession(configuration: .default)
        session.downloadTask(
            with: mediaUrl,
            completionHandler: { temporaryLocation, response, error in
                if let err = error {
                    let desc = err.localizedDescription
                    RDLogger.error("Error with downloading rich push: \(String(describing: desc))")
                    RDPush.sendGraylogMessage(logLevel: PushKey.graylogLogLevelError, logMessage: "Error with downloading rich push: \(String(describing: desc))")
                    contentHandler(modifiedBestAttemptContent)
                    return
                }
                guard let mimeType = response?.mimeType else { return }
                let fileType = self.determineType(fileType: mimeType)
                guard let fileName = temporaryLocation?.lastPathComponent.appending(fileType) else { return }
                let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(fileName)
                do {
                    guard let temporaryLocation = temporaryLocation else { return }
                    try FileManager.default.moveItem(at: temporaryLocation,
                                                     to: temporaryDirectory)
                    let attachment = try UNNotificationAttachment(identifier: "",
                                                                  url: temporaryDirectory, options: nil)
                    modifiedBestAttemptContent.attachments = [attachment]
                    contentHandler(modifiedBestAttemptContent)
                    if FileManager.default.fileExists(atPath: temporaryDirectory.path) {
                        try FileManager.default.removeItem(at: temporaryDirectory)
                    }
                } catch {
                    RDLogger.error("Error with the rich push attachment: \(error)")
                    RDPush.sendGraylogMessage(logLevel: PushKey.graylogLogLevelError, logMessage: "Error with the rich push attachment: \(error)")
                    contentHandler(modifiedBestAttemptContent)
                    return
                }
            }).resume()
    }
    
    static func determineType(fileType: String) -> String {
        switch fileType {
        case "video/mp4":
            return ".mp4"
        case "image/jpeg":
            return ".jpg"
        case "image/gif":
            return ".gif"
        case "image/png":
            return ".png"
        default:
            return ".tmp"
        }
    }
    
}
