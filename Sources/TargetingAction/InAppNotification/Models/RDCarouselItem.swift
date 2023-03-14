//
//  RDCarouselItem.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 15.02.2022.
//

import UIKit

// swiftlint:disable type_body_length
public class RDCarouselItem {

    public enum PayloadKey {
        public static let imageUrlString = "image"
        public static let title = "title"
        public static let titleColor = "title_color"
        public static let titleFontFamily = "title_font_family"
        public static let title_custom_font_family_ios = "title_custom_font_family_ios"
        public static let title_textsize = "title_textsize"
        public static let body = "body"
        public static let body_color = "body_color"
        public static let body_font_family = "body_font_family"
        public static let body_custom_font_family_ios = "body_custom_font_family_ios"
        public static let body_textsize = "body_textsize"
        public static let promocode_type = "promocode_type"
        public static let promotion_code = "promotion_code"
        public static let promocode_background_color = "promocode_background_color"
        public static let promocode_text_color = "promocode_text_color"
        public static let button_text = "button_text"
        public static let button_text_color = "button_text_color"
        public static let button_color = "button_color"
        public static let button_font_family = "button_font_family"
        public static let button_custom_font_family_ios = "button_custom_font_family_ios"
        public static let button_textsize = "button_textsize"
        public static let background_image = "background_image"
        public static let background_color = "background_color"
        public static let ios_lnk = "ios_lnk"
        public static let close_button_color = "close_button_color"
        public static let videourl = "videourl"
        public static let buttonFunction = "button_function"
        public static let buttonBorderRadius = "button_border_radius"
    }

    public let imageUrlString: String?
    public let title: String?
    public let titleColor: UIColor?
    public let titleFontFamily: String?
    public let titleCustomFontFamily: String?
    public let titleTextsize: String?
    public let body: String?
    public let bodyColor: UIColor?
    public let bodyFontFamily: String?
    public let bodyCustomFontFamily: String?
    public let bodyTextsize: String?
    public let promocodeType: String?
    public let promotionCode: String?
    public let promocodeBackgroundColor: UIColor?
    public let promocodeTextColor: UIColor?
    public let buttonText: String?
    public let buttonTextColor: UIColor?
    public let buttonColor: UIColor?
    public let buttonFontFamily: String?
    public let buttonCustomFontFamily: String?
    public let buttonTextsize: String?
    public let backgroundImageString: String?
    public let backgroundColor: UIColor?
    public let linkString: String?
    public var closeButtonColor: UIColor?
    public var videourl: String?
    public var buttonFunction: String?
    public var buttonBorderRadius: String?

    var titleFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2), size: CGFloat(12))
    var bodyFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body), size: CGFloat(8))
    var buttonFont: UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body), size: CGFloat(8))

    var linkUrl: URL?

    var imageUrl: URL?

    var backgroundImageUrl: URL?

    public var fetchImageBlock: FetchImageBlock?

    public init(imageUrlString: String?, title: String?, titleColor: String?, titleFontFamily: String?, titleCustomFontFamily: String?, titleTextsize: String?, body: String?, bodyColor: UIColor?, bodyFontFamily: String?, bodyCustomFontFamily: String?, bodyTextsize: String?, promocodeType: String?, promotionCode: String?, promocodeBackgroundColor: UIColor?, promocodeTextColor: UIColor?, buttonText: String?, buttonTextColor: UIColor?, buttonColor: UIColor?, buttonFontFamily: String?, buttonCustomFontFamily: String?, buttonTextsize: String?, backgroundImageString: String?, backgroundColor: UIColor?, linkString: String?, closeButtonColor: UIColor?, videourl: String?, buttonFunction: String, buttonBorderRadius: String?) {
        self.imageUrlString = imageUrlString
        self.title = title
        self.titleColor = UIColor(hex: titleColor)
        self.titleFontFamily = titleFontFamily
        self.titleCustomFontFamily = titleCustomFontFamily
        self.titleTextsize = titleTextsize
        self.body = body
        self.bodyColor = bodyColor
        self.bodyFontFamily = bodyFontFamily
        self.bodyCustomFontFamily = bodyCustomFontFamily
        self.bodyTextsize = bodyTextsize
        self.promocodeType = promocodeType
        self.promotionCode = promotionCode
        self.promocodeBackgroundColor = promocodeBackgroundColor
        self.promocodeTextColor = promocodeTextColor
        self.buttonText = buttonText
        self.buttonTextColor = buttonTextColor
        self.buttonColor = buttonColor
        self.buttonFontFamily = buttonFontFamily
        self.buttonCustomFontFamily = buttonCustomFontFamily
        self.buttonTextsize = buttonTextsize
        self.backgroundImageString = backgroundImageString
        self.backgroundColor = backgroundColor
        self.linkString = linkString
        self.videourl = videourl
        self.buttonFunction = buttonFunction
        self.buttonBorderRadius = buttonBorderRadius

        if let linkString = linkString, !linkString.isEmptyOrWhitespace {
            self.linkUrl = URL(string: linkString)
        }

        if !imageUrlString.isNilOrWhiteSpace {
            self.imageUrl = RDHelper.getImageUrl(imageUrlString!, type: .inappcarousel)
        }

        if !backgroundImageString.isNilOrWhiteSpace {
            self.backgroundImageUrl = RDHelper.getImageUrl(backgroundImageString!, type: .inappcarousel)
        }

        self.closeButtonColor = closeButtonColor

        self.setFonts()

        self.fetchImageBlock = { imageCompletion in
            var backgroundImage: UIImage?

            if let backgroundImageUrl = self.backgroundImageUrl, let imageData: Data = try? Data(contentsOf: backgroundImageUrl) {
                backgroundImage = UIImage(data: imageData as Data)
            }

            imageCompletion(self.imageUrl, backgroundImage, self)
        }

    }

    // swiftlint:disable function_body_length disable cyclomatic_complexity
    public init?(JSONObject: [String: Any]?) {
        guard let object = JSONObject else {
            RDLogger.error("carouselitem json object should not be nil")
            return nil
        }

        self.imageUrlString = object[PayloadKey.imageUrlString] as? String
        self.title = object[PayloadKey.title] as? String
        self.titleColor = UIColor(hex: object[PayloadKey.titleColor] as? String)
        self.titleFontFamily = object[PayloadKey.titleFontFamily] as? String
        self.titleCustomFontFamily = object[PayloadKey.title_custom_font_family_ios] as? String
        self.titleTextsize = object[PayloadKey.title_textsize] as? String
        self.body = object[PayloadKey.body] as? String
        self.bodyColor = UIColor(hex: object[PayloadKey.body_color] as? String)
        self.bodyFontFamily = object[PayloadKey.body_font_family] as? String
        self.bodyCustomFontFamily = object[PayloadKey.body_custom_font_family_ios] as? String
        self.bodyTextsize = object[PayloadKey.body_textsize] as? String
        self.promocodeType = object[PayloadKey.promocode_type] as? String
        self.promotionCode = object[PayloadKey.promotion_code] as? String
        self.promocodeBackgroundColor = UIColor(hex: object[PayloadKey.promocode_background_color] as? String)
        self.promocodeTextColor = UIColor(hex: object[PayloadKey.promocode_text_color] as? String)
        self.buttonText = object[PayloadKey.button_text] as? String
        self.buttonTextColor = UIColor(hex: object[PayloadKey.button_text_color] as? String)
        self.buttonColor = UIColor(hex: object[PayloadKey.button_color] as? String)
        self.buttonFontFamily = object[PayloadKey.button_font_family] as? String
        self.buttonCustomFontFamily = object[PayloadKey.button_custom_font_family_ios] as? String
        self.buttonTextsize = object[PayloadKey.button_textsize] as? String
        self.backgroundImageString = object[PayloadKey.background_image] as? String
        self.backgroundColor = UIColor(hex: object[PayloadKey.background_color] as? String)
        self.linkString = object[PayloadKey.ios_lnk] as? String
        self.videourl = object[PayloadKey.videourl] as? String
        self.buttonFunction = object[PayloadKey.buttonFunction] as? String
        self.buttonBorderRadius = object[PayloadKey.buttonBorderRadius] as? String

        if let linkString = linkString, !linkString.isEmptyOrWhitespace {
            self.linkUrl = URL(string: linkString)
        }

        if !imageUrlString.isNilOrWhiteSpace {
            self.imageUrl = RDHelper.getImageUrl(imageUrlString!, type: .inappcarousel)
        }

        if !backgroundImageString.isNilOrWhiteSpace {
            self.backgroundImageUrl = RDHelper.getImageUrl(backgroundImageString!, type: .inappcarousel)
        }

        self.closeButtonColor = UIColor(hex: object[PayloadKey.close_button_color] as? String)

        self.setFonts()

        self.fetchImageBlock = { imageCompletion in
            var backgroundImage: UIImage?
            if let backgroundImageUrl = self.backgroundImageUrl, let imageData: Data = try? Data(contentsOf: backgroundImageUrl) {
                backgroundImage = UIImage(data: imageData as Data)
            }

            imageCompletion(self.imageUrl, backgroundImage, self)
        }
    }

    private func setFonts() {
        self.titleFont = RDHelper.getFont(fontFamily: titleFontFamily, fontSize: titleTextsize, style: .title2, customFont: titleCustomFontFamily)
        self.bodyFont = RDHelper.getFont(fontFamily: bodyFontFamily, fontSize: bodyTextsize, style: .body, customFont: bodyCustomFontFamily)
        self.buttonFont = RDHelper.getFont(fontFamily: buttonFontFamily, fontSize: buttonTextsize, style: .title2, customFont: buttonCustomFontFamily)
    }

}
