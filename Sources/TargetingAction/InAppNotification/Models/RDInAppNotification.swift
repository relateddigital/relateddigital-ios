//
//  RDInAppNotification.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 26.12.2021.
//

import UIKit
// swiftlint:disable type_body_length
public class RDInAppNotification {
    public enum PayloadKey {
        public static let actId = "actid"
        public static let actionData = "actiondata"
        public static let messageType = "msg_type"
        public static let messageTitle = "msg_title"
        public static let messageBody = "msg_body"
        public static let buttonText = "btn_text"
        public static let buttonFunction = "button_function"
        public static let iosLink = "ios_lnk"
        public static let imageUrlString = "img"
        public static let visitorData = "visitor_data"
        public static let visitData = "visit_data"
        public static let queryString = "qs"
        public static let messageTitleColor = "msg_title_color"
        public static let messageTitleBackgroundColor = "msg_title_backgroundcolor"
        public static let messageTitleTextSize = "msg_title_textsize"
        public static let messageBodyColor = "msg_body_color"
        public static let messageBodyBackgroundColor = "msg_body_backgroundcolor"
        public static let messageBodyTextSize = "msg_body_textsize"
        public static let fontFamily = "font_family"
        public static let backGround = "background"
        public static let closeButtonColor = "close_button_color"
        public static let buttonTextColor = "button_text_color"
        public static let buttonColor = "button_color"
        public static let alertType = "alert_type"
        public static let closeButtonText = "close_button_text"
        public static let promotionCode = "promotion_code"
        public static let promotionTextColor = "promocode_text_color"
        public static let promotionBackgroundColor = "promocode_background_color"
        public static let numberColors = "number_colors"
        public static let numberRange = "number_range"
        public static let waitingTime = "waiting_time"
        public static let secondPopupType = "secondPopup_type"
        public static let secondPopupMinPoint = "secondPopup_feedbackform_minpoint"
        public static let secondPopupTitle = "secondPopup_msg_title"
        public static let secondPopupBody = "secondPopup_msg_body"
        public static let secondPopupBodyTextSize = "secondPopup_msg_body_textsize"
        public static let secondPopupButtonText = "secondPopup_btn_text"
        public static let secondImageUrlString1 = "secondPopup_image1"
        public static let secondImageUrlString2 = "secondPopup_image2"
        public static let position = "pos"
        public static let customFont = "custom_font_family_ios"
        public static let closePopupActionType = "close_event_trigger"
        public static let carouselItems = "carousel_items"
        public static let videourl = "videourl"
        public static let secondPopupVideourl1 = "secondPopup_videourl1"
        public static let secondPopupVideourl2 = "secondPopup_videourl2"
        public static let secondButtonFunction = "second_button_function"
        public static let secondButtonText = "second_button_text"
        public static let secondButtonTextColor = "second_button_text_color"
        public static let secondButtonColor = "second_button_color"
        public static let secondButtonIosLnk = "second_button_ios_lnk"
        public static let buttonBorderRadius = "button_border_radius"

        
        
        public static let promocodeCopybuttonText = "promocode_copybutton_text"
        public static let promocodeCopybuttonTextColor = "promocode_copybutton_text_color"
        public static let promocodeCopybuttonColor = "promocode_copybutton_color"

        

    }

    let actId: Int
    let messageType: String
    let type: RDInAppNotificationType
    let messageTitle: String?
    let messageBody: String?
    let buttonText: String?
    let buttonFunction: String?
    public let iosLink: String?
    let imageUrlString: String?
    let visitorData: String?
    let visitData: String?
    let queryString: String?
    let messageTitleColor: UIColor?
    let messageTitleBackgroundColor: UIColor?
    let messageTitleTextSize: String?
    let messageBodyColor: UIColor?
    let messageBodyBackgroundColor: UIColor?
    let messageBodyTextSize: String?
    let fontFamily: String?
    let customFont: String?
    let backGroundColor: UIColor?
    let closeButtonColor: UIColor?
    let buttonTextColor: UIColor?
    let buttonColor: UIColor?
    let alertType: String?
    let closeButtonText: String?
    let promotionCode: String?
    let promotionTextColor: UIColor?
    let promotionBackgroundColor: UIColor?
    let numberColors: [UIColor]?
    var numberRange = "1-10"
    let waitingTime: Int?
    let secondPopupType: RDSecondPopupType?
    let secondPopupTitle: String?
    let secondPopupBody: String?
    let secondPopupBodyTextSize: String?
    let secondPopupButtonText: String?
    let secondImageUrlString1: String?
    let secondImageUrlString2: String?
    let secondPopupMinPoint: String?
    let previousPopupPoint: Double?
    let position: RDHalfScreenPosition?
    let closePopupActionType: String?
    public var carouselItems: [RDCarouselItem] = [RDCarouselItem]()
    let videourl: String?
    let secondPopupVideourl1: String?
    let secondPopupVideourl2: String?
    let secondButtonFunction: String?
    let secondButtonText: String?
    let secondButtonTextColor: UIColor?
    let secondButtonColor: UIColor?
    let secondButtonIosLnk: String?
    
    let promocodeCopybuttonText : String?
    let promocodeCopybuttonTextColor : String?
    let promocodeCopybuttonColor : String?
    let buttonBorderRadius : String?

    var imageUrl: URL?

    /// Second Popup First Image
    var secondImageUrl1: URL?


    /// Second Popup Second Image
    var secondImageUrl2: URL?


    let callToActionUrl: URL?
    let callToSecondActionUrl: URL?
    var messageTitleFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2),
                                          size: CGFloat(12))
    var messageBodyFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body),
                                         size: CGFloat(8))
    var buttonTextFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body),
                                        size: CGFloat(8))
    var secondButtonTextFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body),
                                        size: CGFloat(8))

    public init(actId: Int,
                type: RDInAppNotificationType,
                messageTitle: String?,
                messageBody: String?,
                buttonText: String?,
                buttonFunction: String?,
                iosLink: String?,
                imageUrlString: String?,
                visitorData: String?,
                visitData: String?,
                queryString: String?,
                messageTitleColor: String?,
                messageTitleBackgroundColor: String?,
                messageTitleTextSize: String?,
                messageBodyColor: String?,
                messageBodyBackgroundColor: String?,
                messageBodyTextSize: String?,
                fontFamily: String?,
                customFont: String?,
                closePopupActionType: String?,
                backGround: String?,
                closeButtonColor: String?,
                buttonTextColor: String?,
                buttonColor: String?,
                alertType: String?,
                closeButtonText: String?,
                promotionCode: String?,
                promotionTextColor: String?,
                promotionBackgroundColor: String?,
                numberColors: [String]?,
                numberRange: String?,
                waitingTime: Int?,
                secondPopupType: RDSecondPopupType?,
                secondPopupTitle: String?,
                secondPopupBody: String?,
                secondPopupBodyTextSize: String?,
                secondPopupButtonText: String?,
                secondImageUrlString1: String?,
                secondImageUrlString2: String?,
                secondPopupMinPoint: String?,
                previousPopupPoint: Double? = nil,
                position: RDHalfScreenPosition?,
                carouselItems: [RDCarouselItem]? = nil,
                videourl:String?,
                secondPopupVideourl1:String?,
                secondPopupVideourl2:String?,
                secondButtonFunction:String?,
                secondButtonText:String?,
                secondButtonTextColor:String?,
                secondButtonColor:String?,
                secondButtonIosLnk:String?,
                promocodeCopybuttonText:String?,
                promocodeCopybuttonTextColor:String?,
                promocodeCopybuttonColor:String?,
                buttonBorderRadius:String?)
    {
        self.actId = actId
        messageType = type.rawValue
        self.type = type
        self.messageTitle = messageTitle
        self.messageBody = messageBody
        self.buttonText = buttonText
        self.buttonFunction = buttonFunction
        self.iosLink = iosLink
        self.imageUrlString = imageUrlString
        self.visitorData = visitorData
        self.visitData = visitData
        self.queryString = queryString
        self.messageTitleColor = UIColor(hex: messageTitleColor)
        self.messageTitleBackgroundColor = UIColor(hex: messageTitleBackgroundColor)
        self.messageTitleTextSize = messageTitleTextSize
        self.messageBodyColor = UIColor(hex: messageBodyColor)
        self.messageBodyBackgroundColor = UIColor(hex: messageBodyBackgroundColor)
        self.messageBodyTextSize = messageBodyTextSize
        self.fontFamily = fontFamily
        self.customFont = customFont
        self.closePopupActionType = closePopupActionType
        self.secondButtonFunction = secondButtonFunction
        self.secondButtonText = secondButtonText
        self.secondButtonTextColor = UIColor(hex: secondButtonTextColor)
        self.secondButtonColor = UIColor(hex: secondButtonColor)
        self.secondButtonIosLnk = secondButtonIosLnk
        backGroundColor = UIColor(hex: backGround)
        if let cBColor = closeButtonColor {
            if cBColor.lowercased() == "white" {
                self.closeButtonColor = UIColor.white
            } else if cBColor.lowercased() == "black" {
                self.closeButtonColor = UIColor.black
            } else {
                self.closeButtonColor = UIColor(hex: cBColor)
            }
        } else {
            self.closeButtonColor = nil
        }
        self.buttonTextColor = UIColor(hex: buttonTextColor)
        self.buttonColor = UIColor(hex: buttonColor)
        if !imageUrlString.isNilOrWhiteSpace {
            imageUrl = RDHelper.getImageUrl(imageUrlString!, type: self.type)
        }

        var callToActionUrl: URL?
        if let buttonFunction = buttonFunction {
            if buttonFunction == "link" || buttonFunction == ""  {
                if let urlString = iosLink {
                    callToActionUrl = URL(string: urlString)
                }
            } else if buttonFunction == "redirect" {
                callToActionUrl = URL(string: "redirect")
            }
        } else {
            if let urlString = iosLink {
                callToActionUrl = URL(string: urlString)
            }
        }
        
        
        var callToSecondActionUrl: URL?
        if let buttonFunction = secondButtonFunction {
            if buttonFunction == "link" || buttonFunction == "" {
                if let urlString = secondButtonIosLnk {
                    callToSecondActionUrl = URL(string: urlString)
                }
            } else if buttonFunction == "redirect" {
                callToSecondActionUrl = URL(string: "redirect")
            }
        } else {
            if let urlString = secondButtonIosLnk {
                callToSecondActionUrl = URL(string: urlString)
            }
        }
        
        self.callToActionUrl = callToActionUrl
        self.callToSecondActionUrl = callToSecondActionUrl
        self.alertType = alertType
        self.closeButtonText = closeButtonText
        self.promotionCode = promotionCode
        self.promotionTextColor = UIColor(hex: promotionTextColor)
        self.promotionBackgroundColor = UIColor(hex: promotionBackgroundColor)
        self.numberColors = RDHelper.convertColorArray(numberColors)
        self.numberRange = numberRange ?? "1-10"
        self.waitingTime = waitingTime
        self.secondPopupType = secondPopupType
        self.secondPopupTitle = secondPopupTitle
        self.secondPopupBody = secondPopupBody
        self.secondPopupBodyTextSize = secondPopupBodyTextSize
        self.secondPopupButtonText = secondPopupButtonText
        self.secondImageUrlString1 = secondImageUrlString1
        self.secondImageUrlString2 = secondImageUrlString2
        self.secondPopupMinPoint = secondPopupMinPoint
        if !secondImageUrlString1.isNilOrWhiteSpace {
            secondImageUrl1 = RDHelper.getImageUrl(secondImageUrlString1!, type: self.type)
        }
        if !secondImageUrlString2.isNilOrWhiteSpace {
            secondImageUrl2 = RDHelper.getImageUrl(secondImageUrlString2!, type: self.type)
        }
        self.previousPopupPoint = previousPopupPoint
        self.position = position

        if let carouselItems = carouselItems {
            self.carouselItems = carouselItems
        }
        
        self.videourl = videourl
        self.secondPopupVideourl1 = secondPopupVideourl1
        self.secondPopupVideourl2 = secondPopupVideourl2
        
        self.promocodeCopybuttonText = promocodeCopybuttonText
        self.promocodeCopybuttonTextColor = promocodeCopybuttonTextColor
        self.promocodeCopybuttonColor = promocodeCopybuttonColor
        self.buttonBorderRadius = buttonBorderRadius

        setFonts()
    }

    // swiftlint:disable function_body_length disable cyclomatic_complexity
    init?(JSONObject: [String: Any]?) {
        guard let object = JSONObject else {
            RDLogger.error("notification json object should not be nil")
            return nil
        }

        guard let actId = object[PayloadKey.actId] as? Int, actId > 0 else {
            RDLogger.error("invalid \(PayloadKey.actId)")
            return nil
        }

        guard let actionData = object[PayloadKey.actionData] as? [String: Any?] else {
            RDLogger.error("invalid \(PayloadKey.actionData)")
            return nil
        }

        guard let messageType = actionData[PayloadKey.messageType] as? String,
              let type = RDInAppNotificationType(rawValue: messageType) else {
            RDLogger.error("invalid \(PayloadKey.messageType)")
            return nil
        }

        self.actId = actId
        self.messageType = messageType
        self.type = type
        messageTitle = actionData[PayloadKey.messageTitle] as? String
        messageBody = actionData[PayloadKey.messageBody] as? String
        buttonText = actionData[PayloadKey.buttonText] as? String
        buttonFunction = actionData[PayloadKey.buttonFunction] as? String
        iosLink = actionData[PayloadKey.iosLink] as? String
        imageUrlString = actionData[PayloadKey.imageUrlString] as? String
        visitorData = actionData[PayloadKey.visitorData] as? String
        visitData = actionData[PayloadKey.visitData] as? String
        queryString = actionData[PayloadKey.queryString] as? String
        messageTitleColor = UIColor(hex: actionData[PayloadKey.messageTitleColor] as? String)
        messageTitleBackgroundColor = UIColor(hex: actionData[PayloadKey.messageTitleBackgroundColor] as? String)
        messageBodyColor = UIColor(hex: actionData[PayloadKey.messageBodyColor] as? String)
        messageBodyBackgroundColor = UIColor(hex: actionData[PayloadKey.messageBodyBackgroundColor] as? String)
        messageBodyTextSize = actionData[PayloadKey.messageBodyTextSize] as? String
        messageTitleTextSize = actionData[PayloadKey.messageTitleTextSize] as? String ?? messageBodyTextSize
        fontFamily = actionData[PayloadKey.fontFamily] as? String
        customFont = actionData[PayloadKey.customFont] as? String
        closePopupActionType = actionData[PayloadKey.closePopupActionType] as? String
        backGroundColor = UIColor(hex: actionData[PayloadKey.backGround] as? String)
        promotionCode = actionData[PayloadKey.promotionCode] as? String
        promotionTextColor = UIColor(hex: actionData[PayloadKey.promotionTextColor] as? String)
        promotionBackgroundColor = UIColor(hex: actionData[PayloadKey.promotionBackgroundColor] as? String)
        secondButtonFunction = actionData[PayloadKey.secondButtonFunction] as? String
        secondButtonText = actionData[PayloadKey.secondButtonText] as? String
        secondButtonTextColor = UIColor(hex: actionData[PayloadKey.secondButtonTextColor] as? String)
        secondButtonColor = UIColor(hex: actionData[PayloadKey.secondButtonColor] as? String)
        secondButtonIosLnk = actionData[PayloadKey.secondButtonIosLnk] as? String
        promocodeCopybuttonText = actionData[PayloadKey.promocodeCopybuttonText] as? String
        promocodeCopybuttonTextColor = actionData[PayloadKey.promocodeCopybuttonTextColor] as? String
        promocodeCopybuttonColor = actionData[PayloadKey.promocodeCopybuttonColor] as? String
        buttonBorderRadius = actionData[PayloadKey.buttonBorderRadius] as? String
        
        if let cBColor = actionData[PayloadKey.closeButtonColor] as? String {
            if cBColor.lowercased() == "white" {
                closeButtonColor = UIColor.white
            } else if cBColor.lowercased() == "black" {
                closeButtonColor = UIColor.black
            } else {
                closeButtonColor = UIColor(hex: cBColor)
            }
        } else {
            closeButtonColor = nil
        }

        buttonTextColor = UIColor(hex: actionData[PayloadKey.buttonTextColor] as? String)
        buttonColor = UIColor(hex: actionData[PayloadKey.buttonColor] as? String)

        if !imageUrlString.isNilOrWhiteSpace {
            imageUrl = RDHelper.getImageUrl(imageUrlString!, type: self.type)
        }

        var callToActionUrl: URL?
        if let buttonFunction = buttonFunction {
            if buttonFunction == "link" || buttonFunction == "" || buttonFunction == RDConstants.copyRedirect{
                if let urlString = iosLink {
                    callToActionUrl = URL(string: urlString)
                }
            } else if buttonFunction == "redirect" {
                callToActionUrl = URL(string: "redirect")
            }
        } else {
            if let urlString = iosLink {
                callToActionUrl = URL(string: urlString)
            }
        }
        
        
        var callToSecondActionUrl: URL?
        if let buttonFunction = secondButtonFunction {
            if buttonFunction == "link" || buttonFunction == "" || buttonFunction == RDConstants.copyRedirect {
                if let urlString = secondButtonIosLnk {
                    callToSecondActionUrl = URL(string: urlString)
                }
            } else if buttonFunction == "redirect" {
                callToSecondActionUrl = URL(string: "redirect")
            }
        } else {
            if let urlString = secondButtonIosLnk {
                callToSecondActionUrl = URL(string: urlString)
            }
        }
        
        self.callToActionUrl = callToActionUrl
        self.callToSecondActionUrl = callToSecondActionUrl

        alertType = actionData[PayloadKey.alertType] as? String
        closeButtonText = actionData[PayloadKey.closeButtonText] as? String
        if let numColors = actionData[PayloadKey.numberColors] as? [String]? {
            numberColors = RDHelper.convertColorArray(numColors)
        } else {
            numberColors = nil
        }
        numberRange = actionData[PayloadKey.numberRange] as? String ?? "1-10"
        waitingTime = actionData[PayloadKey.waitingTime] as? Int

        // Second Popup Variables
        if let secondType = actionData[PayloadKey.secondPopupType] as? String {
            secondPopupType = RDSecondPopupType(rawValue: secondType)
        } else {
            secondPopupType = nil
        }
        secondPopupTitle = actionData[PayloadKey.secondPopupTitle] as? String
        secondPopupBody = actionData[PayloadKey.secondPopupBody] as? String
        secondPopupBodyTextSize = actionData[PayloadKey.secondPopupBodyTextSize] as? String
        secondPopupButtonText = actionData[PayloadKey.secondPopupButtonText] as? String
        secondImageUrlString1 = actionData[PayloadKey.secondImageUrlString1] as? String
        secondImageUrlString2 = actionData[PayloadKey.secondImageUrlString2] as? String
        videourl = actionData[PayloadKey.videourl] as? String
        secondPopupVideourl1 = actionData[PayloadKey.secondPopupVideourl1] as? String
        secondPopupVideourl2 = actionData[PayloadKey.secondPopupVideourl2] as? String
        
        if !secondImageUrlString1.isNilOrWhiteSpace {
            secondImageUrl1 = RDHelper.getImageUrl(imageUrlString!, type: self.type)
        }
        if !secondImageUrlString2.isNilOrWhiteSpace {
            secondImageUrl2 = RDHelper.getImageUrl(imageUrlString!, type: self.type)
        }
        secondPopupMinPoint = actionData[PayloadKey.secondPopupMinPoint] as? String
        previousPopupPoint = nil

        if let positionString = actionData[PayloadKey.position] as? String
            , let position = RDHalfScreenPosition(rawValue: positionString) {
            self.position = position
        } else {
            position = .bottom
        }

        var carouselItems = [RDCarouselItem]()

        if let carouselItemObjects = actionData[PayloadKey.carouselItems] as? [[String: Any]] {
            for carouselItemObject in carouselItemObjects {
                if let carouselItem = RDCarouselItem(JSONObject: carouselItemObject) {
                    carouselItems.append(carouselItem)
                }
            }
        }

        self.carouselItems = carouselItems.map { (item) -> RDCarouselItem in
            item.closeButtonColor = closeButtonColor
            item.buttonBorderRadius = buttonBorderRadius
            return item
        }
        


        setFonts()
    }

    private func setFonts() {
        messageTitleFont = RDHelper.getFont(fontFamily: fontFamily, fontSize: messageTitleTextSize, style: .title2, customFont: customFont)
        messageBodyFont = RDHelper.getFont(fontFamily: fontFamily, fontSize: messageBodyTextSize, style: .body, customFont: customFont)
        buttonTextFont = RDHelper.getFont(fontFamily: fontFamily, fontSize: messageBodyTextSize, style: .title2, customFont: customFont)
        secondButtonTextFont = RDHelper.getFont(fontFamily: fontFamily, fontSize: messageBodyTextSize, style: .title2, customFont: customFont)
    }
}
