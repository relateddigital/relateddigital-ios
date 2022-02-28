//
//  RDStory.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation

class RDStory {
    internal init(title: String? = nil, smallImg: String? = nil,
                  link: String? = nil, items: [RDStoryItem]? = nil, actid: Int) {
        self.title = title
        self.smallImg = smallImg
        self.link = link
        if let items = items {
            self.items = items
        } else {
            self.items = [RDStoryItem]()
        }
        self.internalIdentifier = UUID().uuidString
        self.actid = actid
    }
    let title: String?
    let smallImg: String?
    let link: String?
    let items: [RDStoryItem]
    let internalIdentifier: String
    var lastPlayedSnapIndex = 0
    var isCompletelyVisible = false
    var isCancelledAbruptly = false
    var clickQueryItems = Properties()
    var impressionQueryItems = Properties()
    var actid: Int
}

extension RDStory: Equatable {
    public static func == (lhs: RDStory, rhs: RDStory) -> Bool {
        return lhs.internalIdentifier == rhs.internalIdentifier
    }
}
