//
//  RDStoryItem.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

enum MimeType: String {
    case photo
    case video
    case unknown
}
class RDStoryItem {
    let internalIdentifier: String
    let mimeType: String
    let url: String
    let displayTime: Int
    let targetUrl: String
    let buttonText: String
    let buttonTextColor: UIColor
    let buttonColor: UIColor
    let countDown:RDStoryCountDown?
    
    var kind: MimeType {
        switch mimeType {
        case MimeType.photo.rawValue:
            return MimeType.photo
        case MimeType.video.rawValue:
            return MimeType.video
        default:
            return MimeType.unknown
        }
    }

    init (fileType: String, displayTime: Int, fileSrc: String,
          targetUrl: String, buttonText: String, buttonTextColor: UIColor,
          buttonColor: UIColor,countDown:RDStoryCountDown) {
        self.mimeType = fileType
        self.displayTime = displayTime // TO_DO:
        self.url = fileSrc // TO_DO:
        self.targetUrl = targetUrl
        self.buttonText = buttonText
        self.internalIdentifier = UUID().uuidString
        self.buttonTextColor = buttonTextColor
        self.buttonColor = buttonColor
        self.countDown = countDown
    }
}

struct RDStoryCountDown {
    var pagePosition:String?
    var messageText:String?
    var messageTextSize:String?
    var messageTextColor:String?
    var displayType:String?
    var endDateTime:String?
    var endAction:String?
    var endAnimationImageUrl:String?
    var gifShown:Bool = false

}
