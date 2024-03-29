//
//  ShakeToWinViewModel.swift
//  VisilabsIOS
//
//  Created by Said Alır on 6.04.2021.
//

import UIKit
import UIKit

struct ShakeToWinViewModel: TargetingActionViewModel {

    var targetingActionType: TargetingActionType
    var actId: Int?
    var title: String?
    var auth: String?

    var mailForm = MailSubscriptionModelGamification()
    var mailExtendedProps = MailSubscriptionExtendedPropsGamification()

    var firstPage: ShakeToWinFirstPage?
    var secondPage: ShakeToWinSecondPage?
    var thirdPage: ShakeToWinThirdPage?

    var backGroundImage: String?
    var soundUrl: String?

    var promocode_background_color: String?
    var promocode_text_color: String?
    var promocode_banner_text: String?
    var promocode_banner_text_color: String?
    var promocode_banner_background_color: String?
    var promocode_banner_button_label: String?
    
    var bannercodeShouldShow : Bool?
    var closeButtonColor: String?

    var report: shakeToWinReport?

    var jsContent: String?
    public var jsonContent: String?

}

struct ShakeToWinFirstPage {
    var image: String?
    var title: String?
    var titleFont: UIFont?
    var titleColor: UIColor?
    var message: String?
    var messageColor: UIColor?
    var messageFont: UIFont?
    var buttonText: String?
    var buttonTextColor: UIColor?
    var buttonFont: UIFont?
    var buttonBgColor: UIColor?
    var backgroundColor: UIColor?
    var closeButtonColor: ButtonColor? = .white
}

struct ShakeToWinSecondPage {
    var waitSeconds: Int?
    var videoURL: URL?
    var backGroundColor: UIColor?
    var closeButtonColor: ButtonColor? = .white
}

// For this page button will be coupon code
struct ShakeToWinThirdPage {
    var image: UIImage?
    var title: String?
    var titleFont: UIFont?
    var titleColor: UIColor?
    var message: String?
    var messageColor: UIColor?
    var messageFont: UIFont?
    var buttonText: String?
    var buttonTextColor: UIColor?
    var buttonFont: UIFont?
    var buttonBgColor: UIColor?
    var backgroundColor: UIColor?
    var iosLink: String?
    var staticCode: String?

    var closeButtonColor: ButtonColor? = .white
}

public struct shakeToWinReport: Codable {
    var impression: String?
    var click: String?
}
