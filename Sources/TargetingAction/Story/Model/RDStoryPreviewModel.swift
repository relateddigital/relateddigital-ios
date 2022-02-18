//
//  RDStoryPreviewModel.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation

class RDStoryPreviewModel: NSObject {

    // MARK: - iVars
    let stories: [RDStory]
    let handPickedStoryIndex: Int // starts with(i)

    // MARK: - Init method
    init(_ stories: [RDStory], _ handPickedStoryIndex: Int) {
        self.stories = stories
        self.handPickedStoryIndex = handPickedStoryIndex
    }

    // MARK: - Functions
    func numberOfItemsInSection(_ section: Int) -> Int {
            return stories.count
    }
    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> RDStory? {
        if indexPath.item < stories.count {
            return stories[indexPath.item]
        } else {
            fatalError("Stories Index mis-matched :(")
        }
    }
}
