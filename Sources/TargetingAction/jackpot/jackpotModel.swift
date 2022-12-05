//
//  FindToWinViewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 29.06.2022.
//

import Foundation

public struct jackpotModel: TargetingActionViewModel,Codable {
    
    public var targetingActionType: TargetingActionType
    var actId: Int? = 0
    var auth = String()
    var title = String()
    var report: JackpotReport? = JackpotReport()
    var mailSubscription: Bool? = false

    var copybutton_label = String()
    var copybutton_function = String()
    var ios_lnk = String()
    
    var mailSubscriptionForm = MailSubscriptionModelGamification()
    var gamificationRules: GamificationRules? = GamificationRules()
    var gameElements: GameElementsFindToWin? = GameElementsFindToWin()
    var gameResultElements: GameResultElementsFindToWin? = GameResultElementsFindToWin()
    var promoCodes: [PromoCodes]? = [PromoCodes]()

    //extended props
    var backgroundImage = String()
    var background_color = String()
    var font_family = String()
    var custom_font_family_ios = String()
    var close_button_color = String()
    var promocode_background_color = String()
    var promocode_text_color = String()
    var copybutton_color = String()
    var copybutton_text_color = String()
    var copybutton_text_size = String()
    var promocode_banner_text = String()
    var promocode_banner_text_color = String()
    var promocode_banner_background_color = String()
    var promocode_banner_button_label = String()
    
    var mailExtendedProps = MailSubscriptionExtendedPropsGamification()
    
    var gamificationRulesExtended : GamificationRulesExtended? = GamificationRulesExtended()
    var gameElementsExtended : GameElementsExtendedFindToWin? = GameElementsExtendedFindToWin()
    var gameResultElementsExtended : GameResultElementsExtendedFindToWin? = GameResultElementsExtendedFindToWin()
    
    var fontFiles: [String] = []
    public var jsContent: String?
}



public struct JackpotReport: Codable {
    var impression: String?
    var click: String?
}
