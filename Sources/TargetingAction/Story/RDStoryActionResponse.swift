//
//  RDStoryActionResponse.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.11.2021.
//

enum RDStoryTemplate: String {
    case storyLookingBanners = "story_looking_banners"
    case skinBased = "skin_based"
}

class RDStoryActionResponse {
    public var storyActions: [RDStoryAction]
    public var error: RDError?
    var guid: String?

    internal init(storyActions: [RDStoryAction], error: RDError? = nil, guid: String?) {
        self.storyActions = storyActions
        self.error = error
        self.guid = guid
    }
}
