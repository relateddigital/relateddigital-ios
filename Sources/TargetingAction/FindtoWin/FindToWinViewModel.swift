//
//  FindToWinViewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 29.06.2022.
//

import Foundation

public struct FindToWinViewModel: TargetingActionViewModel,Codable {
    
    public var targetingActionType: TargetingActionType
    var actId: Int? = 0
    var auth = String()
    var title = String()
    var report: FindToWinReport? = FindToWinReport()
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
}



public struct GameElementsFindToWin : Codable {
    var cardImages = [String]()
    var playgroundRowcount : Int?
    var playgroundColumncount : Int?
    var durationOfGame : Int?
    var soundUrl : String?
}

public struct GameResultElementsFindToWin : Codable {
    var title : String?
    var message : String?
    var loseImage : String?
    var loseButtonLabel : String?
    var loseIosLnk : String?
}

public struct GameElementsExtendedFindToWin : Codable {
    var scoreboardShape : String?
    var scoreboardBackgroundColor : String?
    var scoreboardPageposition : String?
    var backofcardsImage : String?
    var backofcardsColor : String?
    var blankcardImage : String?
}

public struct GameResultElementsExtendedFindToWin : Codable {
    var titleTextColor : String?
    var titleTextSize : String?
    var textColor : String?
    var textSize : String?
    var losebuttonColor : String?
    var losebuttonTextColor : String?
    var losebuttonTextSize : String?
}



public struct FindToWinReport: Codable {
    var impression: String?
    var click: String?
}
