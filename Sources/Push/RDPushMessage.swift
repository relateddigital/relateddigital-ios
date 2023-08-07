//
//  RDPushMessage.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.02.2022.
//

import Foundation

public struct RDPushMessage: PushCodable {
    
    public func getDate() -> Date? {
        guard let dateString = formattedDateString  else {
            return nil
        }
        return PushTools.parseDate(dateString)
    }
    
    public func sendDeliver() -> Bool {
        if let deliver = deliver, deliver.compare("true", options: .caseInsensitive) == .orderedSame {
            return true
        }
        return false
    }
    
    public func isSilent() -> Bool {
        if let silent = silent, silent.compare("true", options: .caseInsensitive) == .orderedSame {
            return true
        }
        return false
    }
    
    public var formattedDateString: String?
    public let aps: Aps?
    public let altURL: String?
    public let cid: String?
    public let url: String?
    public let settings: String?
    public let pushType: String?
    public let altUrl: String?
    public let mediaUrl: String?
    public let fcmOptions: FcmOptions?
    public let deeplink: String?
    public let pushId: String?
    public let emPushSp: String?
    public let elements: [Element]?
    public let buttons: [ActionButtons]?
    public let utm_source: String?
    public let utm_campaign: String?
    public let utm_medium: String?
    public let utm_content: String?
    public let utm_term: String?
    public var notificationLoginID: String?
    public var status: String?
    public var openedDate: String?

    
    public let deliver: String?
    public let silent: String?

    // MARK: - Aps
    public struct Aps: Codable {
        public let alert: Alert?
        public let category: String?
        public let sound: String?
        public let contentAvailable: Int?
    }

    // MARK: - Alert
    public struct Alert: Codable {
        public let title: String?
        public let body: String?
    }

    // MARK: - FcmOptions
    public struct FcmOptions: PushCodable {
        public let image: String?
    }

    // MARK: - Element
    public struct Element: Codable {
//        public let id: Int?
        public let title: String?
        public let content: String?
        public let url: String?
        public let picture: String?
    }

    public struct ActionButtons: Codable {
    public let title: String?
    public let identifier: String?
    public let url: String?
    }
}
