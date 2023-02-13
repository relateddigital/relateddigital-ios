//
//  gameficationViewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 23.05.2022.
//

import Foundation


public struct GiftCatchViewModel : TargetingActionViewModel,Codable {
    
    public var targetingActionType: TargetingActionType
    var actId: Int? = 0
    var auth = String()
    var title = String()
    var report: GameficationReport? = GameficationReport()
    var mailSubscription: Bool? = false

    var copybutton_label = String()
    var copybutton_function = String()
    var ios_lnk = String()
    
    var mailSubscriptionForm = MailSubscriptionModelGamification()
    var gamificationRules: GamificationRules? = GamificationRules()
    var gameElements: GameElements? = GameElements()
    var gameResultElements: GameResultElements? = GameResultElements()
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
    var gameElementsExtended : GameElementsExtended? = GameElementsExtended()
    var gameResultElementsExtended : GameResultElementsExtended? = GameResultElementsExtended()
    
    
    var fontFiles: [String] = []
    
    public var jsContent: String?
    
}

public struct GameficationReport: Codable {
    var impression : String?
    var click : String?
}

public struct GamificationRules : Codable {
    var backgroundImage : String?
    var buttonLabel : String?
}

public struct GameElements : Codable {
    var giftCatcherImage : String?
    var numberOfProducts : Int?
    var downwardSpeed : String?
    var soundUrl : String?
    var giftImages = [String]()
}

public struct GameResultElements : Codable {
    var title : String?
    var message : String?
}


public struct PromoCodes : Codable {
    var rangebottom : Int?
    var rangetop : Int?
    var staticcode : String?
}


public struct GamificationRulesExtended : Codable {
    var buttonColor : String?
    var buttonTextColor : String?
    var buttonTextSize : String?
}


public struct GameElementsExtended : Codable {
    var scoreboardShape : String?
    var scoreboardBackgroundColor : String?
}

public struct GameResultElementsExtended : Codable {
    var titleTextColor : String?
    var titleTextSize : String?
    var textColor : String?
    var textSize : String?
}


public struct MailSubscriptionModelGamification : Codable {
    var auth: String?
    var title: String?
    var message: String?
    var actid: Int?
    var type: String?
    var placeholder: String?
    var buttonTitle: String?
    var consentText: String?
    var successMessage: String?
    var invalidEmailMessage: String?
    var emailPermitText: String?
    var checkConsentMessage: String?
}


public struct MailSubscriptionExtendedPropsGamification : Codable {
    var titleTextColor: String?
    var titleFontFamily: String?
    var titleTextSize: String?
    var textColor: String?
    var textFontFamily: String?
    var textSize: String?
    var buttonColor: String?
    var buttonTextColor: String?
    var buttonTextSize: String?
    var buttonFontFamily: String?
    var emailPermitTextSize: String?
    var emailPermitTextUrl: String?
    var consentTextSize: String?
    var consentTextUrl: String?
    var backgroundColor: String?
    
    var titleCustomFontFamilyIos: String?
    var textCustomFontFamilyIos: String?
    var buttonCustomFontFamilyIos: String?
}

