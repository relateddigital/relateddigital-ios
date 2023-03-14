//
//  RDStoryAction.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

class RDStoryAction {
    let actionId: Int
    let storyTemplate: RDStoryTemplate
    var stories: [RDStory]
    let clickQueryItems: Properties
    let impressionQueryItems: Properties
    let extendedProperties: RDStoryActionExtendedProperties

    init(actionId: Int,
         storyTemplate: RDStoryTemplate,
         stories: [RDStory],
         clickQueryItems: Properties,
         impressionQueryItems: Properties,
         extendedProperties: RDStoryActionExtendedProperties) {
        self.actionId = actionId
        self.storyTemplate = storyTemplate
        self.stories = [RDStory]()
        for story in stories {
            story.clickQueryItems = clickQueryItems
            story.impressionQueryItems = impressionQueryItems
            self.stories.append(story)
        }
        self.clickQueryItems = clickQueryItems
        self.impressionQueryItems = impressionQueryItems
        self.extendedProperties = extendedProperties
    }
}

class RDStoryActionExtendedProperties {
    var imageBorderWidth = 2  // 0,1,2,3
    var imageBorderRadius = 0.5 // "","50%","10%"
    var imageBoxShadow = false
    // var imageBoxShadow: String? // "rgba(0,0,0,0.4) 5px 5px 10px" // TO_DO: buna sonra bak
    var imageBorderColor = UIColor.clear // "#cc3a3a"
    var labelColor = UIColor.black // "#a83c3c"
    var moveShownToEnd = true
    var storyzLabelColor: String = ""
    var fontFamily: String = ""
    var customFontFamilyIos: String = ""

}
