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
        
        if pushDetail.sendDeliver() {
            if let shared = RDPush.shared {
                shared.networkQueue.async {
                    RDPush.emDeliverHandler?.reportDeliver(message: pushDetail)
                }
            }
        }
        
        PushUserDefaultsUtils.savePayload(payload: pushDetail)

        // Setup carousel buttons
        if pushDetail.aps?.category == "carousel" {
            UNUNC.current().setNotificationCategories(getCarouselActionCategorySet())
        }

        // Setup notification for image/video
        guard let modifiedBestAttemptContent = bestAttemptContent else { return }
        
        if let sound = pushDetail.aps?.sound, sound.count > 0 {
            modifiedBestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        }
        
        if pushDetail.pushType == "Image" || pushDetail.pushType == "Video",
            let attachmentMedia = pushDetail.mediaUrl, let mediaUrl = URL(string: attachmentMedia) {
            loadAttachments(mediaUrl: mediaUrl, modifiedBestAttemptContent: modifiedBestAttemptContent, withContentHandler: contentHandler)
        } else if pushDetail.pushType == "Text" {
            contentHandler(modifiedBestAttemptContent)
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
