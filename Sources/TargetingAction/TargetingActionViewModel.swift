//
//  TargetingActionViewModel.swift
//  VisilabsIOS
//
//  Created by Egemen Gulkilik on 5.03.2021.
//

import Foundation

public enum TargetingActionType: String, Codable {
    case mailSubscriptionForm = "MailSubscriptionForm"
    case spinToWin = "SpinToWin"
    case scratchToWin = "ScratchToWin"
    case productStatNotifier = "ProductStatNotifier"
    case drawer = "Drawer"
    case downHsView = "downHsView"
    case giftCatch = "giftrain"
    case findToWin = "findtowin"
    case shakeToWin = "ShakeToWin"
    case giftBox = "giftBox"
    case chooseFavorite = "Choosefavorite"
    case slotMachine = "slotMachine"
    case clawMachine = "ClawMachine"
    case mobileCustomActions = "mobileCustomActions"
    case apprating = "MobileAppRating"

}

public protocol TargetingActionViewModel {
    var targetingActionType: TargetingActionType { get set }
    var jsContent: String? { get set }
    var jsonContent: String? { get set }
}
