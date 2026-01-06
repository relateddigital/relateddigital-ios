//
//  CountdownTimerBannerModel.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 25.07.2024.
//

import Foundation
import UIKit

public struct CountdownTimerBannerModel: TargetingActionViewModel {
    public var targetingActionType: TargetingActionType
    public var jsContent: String?
    public var jsonContent: String?
    
    public var actId: Int?
    public var title: String?
    public var waitingTime: Int = 0
    public var scratch_color: String?
    public var ios_lnk: String?
    public var img: String?
    public var content_body: String?
    public var counter_Date: String?
    public var counter_Time: String?
    
    public var background_color: String?
    public var counter_color: String?
    public var close_button_color: String?
    public var content_body_text_color: String?
    public var position_on_page: String?
    public var content_body_font_family: String?
    public var txtStartDate: String?
}
