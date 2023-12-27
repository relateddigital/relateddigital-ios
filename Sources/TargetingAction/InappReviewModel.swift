//
//  InappReviewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 27.12.2023.
//

import Foundation


struct InappReviewModel : TargetingActionViewModel, Codable {
   
    var targetingActionType: TargetingActionType
    var auth: String?
    var actId: Int?
    var type: String?
    var title: String?
    var jsContent: String?
    var jsonContent: String?
    
    
}
