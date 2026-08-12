//
//  PlinkoModel.swift
//  RelatedDigitalIOS
//
//  Plinko oyunu view model'i. Çarkıfelek (SpinToWin) modeli baz alınmıştır;
//  slices dizisi topun düşebileceği slotları temsil eder.
//

import Foundation

public struct PlinkoSliceViewModel: Codable {
    var displayName: String
    var color: String
    var code: String
    var type: String
    var isAvailable: Bool
    var iosLink: String
    var infotext: String
}

struct PlinkoModel: TargetingActionViewModel, Codable {

    var targetingActionType: TargetingActionType
    var actId: Int = 0
    var title = String()
    var auth = String()
    var promoAuth = String()
    var type = String()
    var mailSubscription = false
    var promocodeTitle = String()
    var copyButtonFunction = String()
    var slices: [PlinkoSliceViewModel] = []
    var report: PlinkoReport? = PlinkoReport()
    var waitingTime: Int = 0

    var fontFiles: [String] = []
    public var jsContent: String?
    public var jsonContent: String?

    // Banner + native tarafında kullanılan özelleştirme alanları (ExtendedProps)
    var font_family = String()
    var custom_font_family_ios = String()
    var close_button_color = String()
    var copybutton_color = String()
    var copybutton_text_color = String()
    var copybutton_text_size = String()
    var promocode_banner_text = String()
    var promocode_banner_text_color = String()
    var promocode_banner_background_color = String()
    var promocode_banner_button_label = String()

    var bannercodeShouldShow: Bool?
    var bannerCode: String?
}

public struct PlinkoReport: Codable {
    var impression: String?
    var click: String?
}
