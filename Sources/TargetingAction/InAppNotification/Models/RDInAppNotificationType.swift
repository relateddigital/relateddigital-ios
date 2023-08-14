//
//  RDInAppNotificationType.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.10.2021.
//

import Foundation

public enum RDInAppNotificationType: String, CaseIterable {
    case mini
    case full
    case imageTextButton = "image_text_button"
    case fullImage = "full_image"
    case nps
    case imageButton = "image_button"
    case smileRating = "smile_rating"
    case emailForm = "subscription_email"
    case alert
    case npsWithNumbers = "nps_with_numbers"
    case halfScreenImage = "half_screen_image"
    case scratchToWin = "scratch_to_win"
    case secondNps = "nps_with_secondpopup"
    case inappcarousel = "inappcarousel"
    case imageButtonImage
    case spintowin
    case feedbackForm
    case productStatNotifier = "product_stat_notifier"
    case drawer = "drawer"
    case gamification = "giftrain"
    case findToWin = "findtowin"
    case video = "video"
    case downHsView = "downHsView"
    case bannerCarousel = "banner_carousel"
    case shakeToWin = "ShakeToWin"
    case giftBox = "giftBox"
    case choosefavorite = "Choosefavorite"
    case slotMachine = "slotMachine"

}

public enum RDSecondPopupType: String, CaseIterable {
    case imageTextButton = "image_text_button"
    case imageButtonImage = "image_text_button_image"
    case feedback = "feedback_form"
}

public enum RDHalfScreenPosition: String, CaseIterable {
    case top = "top"
    case bottom = "bottom"
}

public enum RDProductStatNotifierPosition: String, CaseIterable {
    case top = "top"
    case bottom = "bottom"
}
