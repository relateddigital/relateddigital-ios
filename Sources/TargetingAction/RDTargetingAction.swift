//
//  RDTargetingAction.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit
// swiftlint:disable type_body_length
class RDTargetingAction {

    let rdProfile: RDProfile

    required init(lock: RDReadWriteLock, rdProfile: RDProfile) {
        self.notificationsInstance = RDInAppNotifications(lock: lock)
        self.rdProfile = rdProfile
    }

    private func prepareHeaders(_ rdUser: RDUser) -> Properties {
        var headers = Properties()
        headers["User-Agent"] = rdUser.userAgent
        return headers
    }

    // MARK: - InApp Notifications

    var notificationsInstance: RDInAppNotifications

    var inAppDelegate: RDInAppNotificationsDelegate? {
        get {
            return notificationsInstance.delegate
        }
        set {
            notificationsInstance.delegate = newValue
        }
    }

    func checkInAppNotification(properties: Properties, rdUser: RDUser, completion: @escaping ((_ response: RDInAppNotification?) -> Void)) {
        let semaphore = DispatchSemaphore(value: 0)
        let headers = prepareHeaders(rdUser)
        var notifications = [RDInAppNotification]()
        var props = properties
        props["OM.vcap"] = rdUser.visitData
        props["OM.viscap"] = rdUser.visitorData
        props[RDConstants.nrvKey] = String(rdUser.nrv)
        props[RDConstants.pvivKey] = String(rdUser.pviv)
        props[RDConstants.tvcKey] = String(rdUser.tvc)
        props[RDConstants.lvtKey] = rdUser.lvt

        for (key, value) in RDPersistence.readTargetParameters() {
           if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
               props[key] = value
           }
        }
        
        props[RDConstants.pushPermitPermissionReqKey] = RDConstants.pushPermitStatus

        RDRequest.sendInAppNotificationRequest(properties: props, headers: headers, completion: { rdInAppNotificationResult in
            guard let result = rdInAppNotificationResult else {
                semaphore.signal()
                completion(nil)
                return
            }

            for rawNotif in result {
                if let actionData = rawNotif["actiondata"] as? [String: Any] {
                    if let typeString = actionData["msg_type"] as? String,
                       RDInAppNotificationType(rawValue: typeString) != nil,
                       let notification = RDInAppNotification(JSONObject: rawNotif) {
                        notifications.append(notification)
                    }
                }
            }
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        RDLogger.info("in app notification check: \(notifications.count) found." +
                            " actid's: \(notifications.map({String($0.actId)}).joined(separator: ","))")

        completion(notifications.first)
    }

    // MARK: - Targeting Actions

    func checkTargetingActions(properties: Properties, rdUser: RDUser, completion: @escaping ((_ response: TargetingActionViewModel?) -> Void)) {

        let semaphore = DispatchSemaphore(value: 0)
        var targetingActionViewModel: TargetingActionViewModel?
        var props = properties
        props["OM.vcap"] = rdUser.visitData
        props["OM.viscap"] = rdUser.visitorData
        props[RDConstants.nrvKey] = String(rdUser.nrv)
        props[RDConstants.pvivKey] = String(rdUser.pviv)
        props[RDConstants.tvcKey] = String(rdUser.tvc)
        props[RDConstants.lvtKey] = rdUser.lvt
        
        
        props[RDConstants.actionType] = "\(RDConstants.mailSubscriptionForm)~\(RDConstants.spinToWin)~\(RDConstants.scratchToWin)~\(RDConstants.productStatNotifier)~\(RDConstants.drawer)"

        for (key, value) in RDPersistence.readTargetParameters() {
           if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
               props[key] = value
           }
        }
        
        props[RDConstants.pushPermitPermissionReqKey] = RDConstants.pushPermitStatus

        RDRequest.sendMobileRequest(properties: props, headers: prepareHeaders(rdUser), completion: {(result: [String: Any]?, _: RDError?, _: String?) in
            guard let result = result else {
                semaphore.signal()
                completion(nil)
                return
            }
            targetingActionViewModel = self.parseTargetingAction(result)
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        completion(targetingActionViewModel)
    }

    func parseTargetingAction(_ result: [String: Any]?) -> TargetingActionViewModel? {
        guard let result = result else { return nil }
        if let mailFormArr = result[RDConstants.mailSubscriptionForm] as? [[String: Any?]], let mailForm = mailFormArr.first {
            if let actionData = mailForm[RDConstants.actionData] as? [String: Any] {
                let taTemplate = actionData[RDConstants.taTemplate] as? String ?? ""
                if taTemplate == RDConstants.customizable {
                    return parseDownHsView(mailForm)
                }
            }
            return parseMailForm(mailForm)
        } else if let spinToWinArr = result[RDConstants.spinToWin] as? [[String: Any?]], let spinToWin = spinToWinArr.first {
            return parseSpinToWin(spinToWin)
        } else if let sctwArr = result[RDConstants.scratchToWin] as? [[String: Any?]], let sctw = sctwArr.first {
            return parseScratchToWin(sctw)
        } else if let drawerArr = result[RDConstants.drawer] as? [[String: Any?]], let drw = drawerArr.first {
            return parseDrawer(drw)
        } else if let downHsViewArr = result[RDConstants.downHsView] as? [[String: Any?]], let downHs = downHsViewArr.first {
            return parseDownHsView(downHs)
        } else if let psnArr = result[RDConstants.productStatNotifier] as? [[String: Any?]], let psn = psnArr.first {
            if let productStatNotifier = parseProductStatNotifier(psn) {
                if productStatNotifier.attributedString == nil {
                    return nil
                }
                if productStatNotifier.contentCount < productStatNotifier.threshold {
                    RDLogger.warn("Product stat notifier: content count below threshold.")
                    return nil
                }
                return productStatNotifier
            }
        }
        return nil
    }
    
    // MARK: SpinToWin

    private func parseSpinToWin(_ spinToWin: [String: Any?]) -> SpinToWinViewModel? {
        guard let actionData = spinToWin[RDConstants.actionData] as? [String: Any] else { return nil }
        guard let slices = actionData[RDConstants.slices] as? [[String: Any]] else { return nil }
        guard let spinToWinContent = actionData[RDConstants.spinToWinContent] as? [String: Any] else { return nil }
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        // guard let report = actionData[VisilabsConstants.report] as? [String: Any] else { return nil } //mail_subscription false olduğu zaman report gelmiyor.

        let taTemplate = actionData[RDConstants.taTemplate] as? String ?? "half_spin"
        let img = actionData[RDConstants.img] as? String ?? ""

        let report = actionData[RDConstants.report] as? [String: Any] ?? [String: Any]()
        let actid = spinToWin[RDConstants.actid] as? Int ?? 0
        let auth = actionData[RDConstants.authentication] as? String ?? ""
        let promoAuth = actionData[RDConstants.promoAuth] as? String ?? ""
        let type = actionData[RDConstants.type] as? String ?? "spin_to_win_email"
        let mailSubscription = actionData[RDConstants.mailSubscription] as? Bool ?? false
        let sliceCount = actionData[RDConstants.sliceCount] as? String ?? ""
        let promocodesSoldoutMessage = actionData[RDConstants.promocodesSoldoutMessage] as? String ?? ""
        // report
        let impression = report[RDConstants.impression] as? String ?? ""
        let click = report[RDConstants.click] as? String ?? ""
        let spinToWinReport = SpinToWinReport(impression: impression, click: click)

        // spin_to_win_content
        let title = spinToWinContent[RDConstants.title] as? String ?? ""
        let message = spinToWinContent[RDConstants.message] as? String ?? ""
        let placeholder = spinToWinContent[RDConstants.placeholder] as? String ?? ""
        let buttonLabel = spinToWinContent[RDConstants.buttonLabel] as? String ?? ""
        let consentText = spinToWinContent[RDConstants.consentText] as? String ?? ""
        let invalidEmailMessage = spinToWinContent[RDConstants.invalidEmailMessage] as? String ?? ""
        let successMessage = spinToWinContent[RDConstants.successMessage] as? String ?? ""
        let emailPermitText = spinToWinContent[RDConstants.emailPermitText] as? String ?? ""
        let checkConsentMessage = spinToWinContent[RDConstants.checkConsentMessage] as? String ?? ""
        let promocodeTitle = actionData[RDConstants.promocodeTitle] as? String ?? ""
        let copybuttonLabel = actionData[RDConstants.copybuttonLabel] as? String ?? ""
        let wheelSpinAction = actionData[RDConstants.wheelSpinAction] as? String ?? ""

        // extended properties
        let displaynameTextColor = extendedProps[RDConstants.displaynameTextColor] as? String ?? ""
        let displaynameFontFamily = extendedProps[RDConstants.displaynameFontFamily] as? String ?? ""
        let displaynameTextSize = extendedProps[RDConstants.displaynameTextSize] as? String ?? ""
        let titleTextColor = extendedProps[RDConstants.titleTextColor] as? String ?? ""
        let titleFontFamily = extendedProps[RDConstants.titleFontFamily] as? String ?? ""
        let titleTextSize = extendedProps[RDConstants.titleTextSize] as? String ?? ""
        let textColor = extendedProps[RDConstants.textColor] as? String ?? ""
        let textFontFamily = extendedProps[RDConstants.textFontFamily] as? String ?? ""
        let textSize = extendedProps[RDConstants.textSize] as? String ?? ""
        let button_color = extendedProps[RDConstants.button_color] as? String ?? ""
        let button_text_color = extendedProps[RDConstants.button_text_color] as? String ?? ""
        let buttonFontFamily = extendedProps[RDConstants.buttonFontFamily] as? String ?? ""
        let buttonTextSize = extendedProps[RDConstants.buttonTextSize] as? String ?? ""
        let promocodeTitleTextColor = extendedProps[RDConstants.promocodeTitleTextColor] as? String ?? ""
        let promocodeTitleFontFamily = extendedProps[RDConstants.promocodeTitleFontFamily] as? String ?? ""
        let promocodeTitleTextSize = extendedProps[RDConstants.promocodeTitleTextSize] as? String ?? ""
        let promocodeBackgroundColor = extendedProps[RDConstants.promocodeBackgroundColor] as? String ?? ""
        let promocodeTextColor = extendedProps[RDConstants.promocodeTextColor] as? String ?? ""
        let copybuttonColor = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        let copybuttonTextColor = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        let copybuttonFontFamily = extendedProps[RDConstants.copybuttonFontFamily] as? String ?? ""
        let copybuttonTextSize = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        let emailpermitTextSize = extendedProps[RDConstants.emailpermitTextSize] as? String ?? ""
        let emailpermitTextUrl = extendedProps[RDConstants.emailpermitTextUrl] as? String ?? ""
        
        
        let displaynameCustomFontFamilyIos = extendedProps[RDConstants.displaynameCustomFontFamilyIos] as? String ?? ""
        let titleCustomFontFamilyIos = extendedProps[RDConstants.titleCustomFontFamilyIos] as? String ?? ""
        let textCustomFontFamilyIos = extendedProps[RDConstants.textCustomFontFamilyIos] as? String ?? ""
        let buttonCustomFontFamilyIos = extendedProps[RDConstants.buttonCustomFontFamilyIos] as? String ?? ""
        let promocodeTitleCustomFontFamilyIos = extendedProps[RDConstants.promocodeTitleCustomFontFamilyIos] as? String ?? ""
        let copybuttonCustomFontFamilyIos = extendedProps[RDConstants.copybuttonCustomFontFamilyIos] as? String ?? ""
        let promocodesSoldoutMessageCustomFontFamilyIos = extendedProps[RDConstants.promocodesSoldoutMessageCustomFontFamilyIos] as? String ?? ""

        let consentTextSize = extendedProps[RDConstants.consentTextSize] as? String ?? ""
        let consentTextUrl = extendedProps[RDConstants.consentTextUrl] as? String ?? ""
        let closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        let backgroundColor = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        
        let wheelBorderWidth = extendedProps[RDConstants.wheelBorderWidth] as? String ?? ""
        let wheelBorderColor = extendedProps[RDConstants.wheelBorderColor] as? String ?? ""
        let sliceDisplaynameFontFamily = extendedProps[RDConstants.sliceDisplaynameFontFamily] as? String ?? ""
        
        
        let promocodesSoldoutMessageTextColor = extendedProps[RDConstants.promocodes_soldout_message_text_color] as? String ?? ""
        let promocodesSoldoutMessageFontFamily = extendedProps[RDConstants.promocodes_soldout_message_font_family] as? String ?? ""
        let promocodesSoldoutMessageTextSize = extendedProps[RDConstants.promocodes_soldout_message_text_size] as? String ?? ""
        let promocodesSoldoutMessageBackgroundColor = extendedProps[RDConstants.promocodes_soldout_message_background_color] as? String ?? ""
        
        let titlePosition = extendedProps[RDConstants.title_position] as? String ?? ""
        let textPosition = extendedProps[RDConstants.text_position] as? String ?? ""
        let buttonPosition = extendedProps[RDConstants.button_position] as? String ?? ""
        let copybuttonPosition = extendedProps[RDConstants.copybutton_position] as? String ?? ""
        
        let promocodeBannerText = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        let promocodeBannerTextColor = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        let promocodeBannerBackgroundColor = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        let promocodeBannerButtonLabel = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""

        var sliceArray = [SpinToWinSliceViewModel]()

        for slice in slices {
            let displayName = slice[RDConstants.displayName] as? String ?? ""
            let color = slice[RDConstants.color] as? String ?? ""
            let code = slice[RDConstants.code] as? String ?? ""
            let type = slice[RDConstants.type] as? String ?? ""
            let isAvailable = slice[RDConstants.isAvailable] as? Bool ?? true
            let spinToWinSliceViewModel = SpinToWinSliceViewModel(displayName: displayName, color: color, code: code, type: type, isAvailable: isAvailable)
            sliceArray.append(spinToWinSliceViewModel)
        }

        let model = SpinToWinViewModel(targetingActionType: .spinToWin, actId: actid, auth: auth, promoAuth: promoAuth, type: type, title: title, message: message, placeholder: placeholder, buttonLabel: buttonLabel, consentText: consentText, emailPermitText: emailPermitText, successMessage: successMessage, invalidEmailMessage: invalidEmailMessage, checkConsentMessage: checkConsentMessage, promocodeTitle: promocodeTitle, copyButtonLabel: copybuttonLabel, mailSubscription: mailSubscription, sliceCount: sliceCount, slices: sliceArray, report: spinToWinReport, taTemplate: taTemplate, img: img, wheelSpinAction: wheelSpinAction, promocodesSoldoutMessage: promocodesSoldoutMessage, displaynameTextColor: displaynameTextColor, displaynameFontFamily: displaynameFontFamily, displaynameTextSize: displaynameTextSize, titleTextColor: titleTextColor, titleFontFamily: titleFontFamily, titleTextSize: titleTextSize, textColor: textColor, textFontFamily: textFontFamily, textSize: textSize, buttonColor: button_color, buttonTextColor: button_text_color, buttonFontFamily: buttonFontFamily, buttonTextSize: buttonTextSize, promocodeTitleTextColor: promocodeTitleTextColor, promocodeTitleFontFamily: promocodeTitleFontFamily, promocodeTitleTextSize: promocodeTitleTextSize, promocodeBackgroundColor: promocodeBackgroundColor, promocodeTextColor: promocodeTextColor, copybuttonColor: copybuttonColor, copybuttonTextColor: copybuttonTextColor, copybuttonFontFamily: copybuttonFontFamily, copybuttonTextSize: copybuttonTextSize, emailpermitTextSize: emailpermitTextSize, emailpermitTextUrl: emailpermitTextUrl, consentTextSize: consentTextSize, consentTextUrl: consentTextUrl, closeButtonColor: closeButtonColor, backgroundColor: backgroundColor,wheelBorderWidth: wheelBorderWidth,wheelBorderColor: wheelBorderColor,sliceDisplaynameFontFamily: sliceDisplaynameFontFamily, promocodesSoldoutMessageTextColor: promocodesSoldoutMessageTextColor, promocodesSoldoutMessageFontFamily: promocodesSoldoutMessageFontFamily, promocodesSoldoutMessageTextSize: promocodesSoldoutMessageTextSize, promocodesSoldoutMessageBackgroundColor: promocodesSoldoutMessageBackgroundColor,displaynameCustomFontFamilyIos:displaynameCustomFontFamilyIos ,titleCustomFontFamilyIos:titleCustomFontFamilyIos,textCustomFontFamilyIos:textCustomFontFamilyIos,buttonCustomFontFamilyIos:buttonCustomFontFamilyIos,promocodeTitleCustomFontFamilyIos:promocodeTitleCustomFontFamilyIos,copybuttonCustomFontFamilyIos:copybuttonCustomFontFamilyIos,promocodesSoldoutMessageCustomFontFamilyIos:promocodesSoldoutMessageCustomFontFamilyIos, titlePosition: titlePosition, textPosition: textPosition, buttonPosition: buttonPosition, copybuttonPosition: copybuttonPosition, promocodeBannerText: promocodeBannerText, promocodeBannerTextColor: promocodeBannerTextColor, promocodeBannerBackgroundColor: promocodeBannerBackgroundColor, promocodeBannerButtonLabel: promocodeBannerButtonLabel)

        return model
    }


    // MARK: ProductStatNotifier

    private func parseProductStatNotifier(_ productStatNotifier: [String: Any?]) -> RDProductStatNotifierViewModel? {
        guard let actionData = productStatNotifier[RDConstants.actionData] as? [String: Any] else { return nil }
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        let content = actionData[RDConstants.content] as? String ?? ""
        let timeout = actionData[RDConstants.timeout] as? String ?? ""
        var position = RDProductStatNotifierPosition.bottom
        if let positionString = actionData[RDConstants.pos] as? String, let pos = RDProductStatNotifierPosition.init(rawValue: positionString) {
            position = pos
        }
        let bgcolor = actionData[RDConstants.bgcolor] as? String ?? ""
        let threshold = actionData[RDConstants.threshold] as? Int ?? 0
        let showclosebtn = actionData[RDConstants.showclosebtn] as? Bool ?? false
        
        // extended properties
        let content_text_color = extendedProps[RDConstants.content_text_color] as? String ?? ""
        let content_font_family = extendedProps[RDConstants.content_font_family] as? String ?? ""
        let content_text_size = extendedProps[RDConstants.content_text_size] as? String ?? ""
        let contentcount_text_color = extendedProps[RDConstants.contentcount_text_color] as? String ?? ""
        let contentcount_text_size = extendedProps[RDConstants.contentcount_text_size] as? String ?? ""
        let closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? "black"
        
        var productStatNotifier = RDProductStatNotifierViewModel(targetingActionType: .productStatNotifier, content: content, timeout: timeout, position: position, bgcolor: bgcolor, threshold: threshold, showclosebtn: showclosebtn, content_text_color: content_text_color, content_font_family: content_font_family, content_text_size: content_text_size, contentcount_text_color: contentcount_text_color, contentcount_text_size: contentcount_text_size, closeButtonColor: closeButtonColor)
        productStatNotifier.setAttributedString()
        return productStatNotifier
    }
    
    
    private func parseDownHsView(_ downHsView: [String: Any?]) -> downHsViewServiceModel? {

        guard let actionData = downHsView[RDConstants.actionData] as? [String: Any] else { return nil }
        var downHsViewServiceModel = downHsViewServiceModel(targetingActionType: .downHsView)
        downHsViewServiceModel.actId = downHsView[RDConstants.actid] as? Int ?? 0
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        
        downHsViewServiceModel.title = actionData[RDConstants.title] as? String ?? ""
        downHsViewServiceModel.message = actionData[RDConstants.message] as? String ?? ""
        downHsViewServiceModel.buttonLabel = actionData[RDConstants.buttonLabel] as? String ?? ""
        downHsViewServiceModel.consentText = actionData[RDConstants.consentText] as? String
        downHsViewServiceModel.successMessage = actionData[RDConstants.successMessage] as? String ?? ""
        downHsViewServiceModel.invalidEmailMessage = actionData[RDConstants.invalidEmailMessage] as? String ?? ""
        downHsViewServiceModel.emailPermitText = actionData[RDConstants.emailPermitText] as? String ?? ""
        downHsViewServiceModel.checkConsentMessage = actionData[RDConstants.checkConsentMessage] as? String ?? ""
        downHsViewServiceModel.placeholder = actionData[RDConstants.placeholder] as? String ?? ""
        downHsViewServiceModel.img = actionData[RDConstants.img] as? String ?? ""


        //extended props
        downHsViewServiceModel.titleTextColor = extendedProps[RDConstants.titleTextColor] as? String ?? ""
        downHsViewServiceModel.titleFontFamily = extendedProps[RDConstants.titleFontFamily] as? String ?? ""
        downHsViewServiceModel.titleTextSize = extendedProps[RDConstants.titleTextSize] as? String ?? ""
        downHsViewServiceModel.textColor = extendedProps[RDConstants.textColor] as? String ?? ""
        downHsViewServiceModel.textFontFamily = extendedProps[RDConstants.textFontFamily] as? String ?? ""
        downHsViewServiceModel.textSize = extendedProps[RDConstants.textSize] as? String ?? ""
        downHsViewServiceModel.buttonColor = extendedProps[RDInAppNotification.PayloadKey.buttonColor] as? String ?? ""
        downHsViewServiceModel.buttonTextColor = extendedProps[RDInAppNotification.PayloadKey.buttonTextColor] as? String ?? ""
        downHsViewServiceModel.buttonTextSize = extendedProps[RDConstants.buttonTextSize] as? String ?? ""
        downHsViewServiceModel.buttonFontFamily = extendedProps[RDConstants.buttonFontFamily] as? String ?? ""
        downHsViewServiceModel.emailPermitTextSize = extendedProps[RDConstants.emailPermitTextSize] as? String ?? ""
        downHsViewServiceModel.emailPermitTextUrl = extendedProps[RDConstants.emailPermitTextUrl] as? String ?? ""
        downHsViewServiceModel.consentTextSize = extendedProps[RDConstants.consentTextSize] as? String ?? ""
        downHsViewServiceModel.consentTextUrl = extendedProps[RDConstants.consentTextUrl] as? String ?? ""
        downHsViewServiceModel.closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? "black"
        downHsViewServiceModel.backgroundColor = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        
        downHsViewServiceModel.titleCustomFontFamilyIos = extendedProps[RDConstants.titleCustomFontFamilyIos] as? String ?? ""
        downHsViewServiceModel.textCustomFontFamilyIos = extendedProps[RDConstants.textCustomFontFamilyIos] as? String ?? ""
        downHsViewServiceModel.buttonCustomFontFamilyIos = extendedProps[RDConstants.buttonCustomFontFamilyIos] as? String ?? ""
        downHsViewServiceModel.textPosition = extendedProps[RDConstants.textPosition] as? String ?? ""
        downHsViewServiceModel.imagePosition = extendedProps[RDConstants.imagePosition] as? String ?? ""

        
        return downHsViewServiceModel
    }

    // MARK: MailSubscriptionForm

    private func parseMailForm(_ mailForm: [String: Any?]) -> MailSubscriptionViewModel? {
        guard let actionData = mailForm[RDConstants.actionData] as? [String: Any] else { return nil }
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        guard let report = actionData[RDConstants.report] as? [String: Any] else { return nil }
        let title = actionData[RDConstants.title] as? String ?? ""
        let message = actionData[RDConstants.message] as? String ?? ""
        let actid = mailForm[RDConstants.actid] as? Int ?? 0
        let type = actionData[RDConstants.type] as? String ?? "subscription_email"
        let buttonText = actionData[RDConstants.buttonLabel] as? String ?? ""
        let auth = actionData[RDConstants.authentication] as? String ?? ""
        let consentText = actionData[RDConstants.consentText] as? String
        let successMsg = actionData[RDConstants.successMessage] as? String ?? ""
        let invalidMsg = actionData[RDConstants.invalidEmailMessage] as? String ?? ""
        let emailPermitText = actionData[RDConstants.emailPermitText] as? String ?? ""
        let checkConsent = actionData[RDConstants.checkConsentMessage] as? String ?? ""
        let placeholder = actionData[RDConstants.placeholder] as? String ?? ""

        let titleTextColor = extendedProps[RDConstants.titleTextColor] as? String ?? ""
        let titleFontFamily = extendedProps[RDConstants.titleFontFamily] as? String ?? ""
        let titleTextSize = extendedProps[RDConstants.titleTextSize] as? String ?? ""
        let textColor = extendedProps[RDConstants.textColor] as? String ?? ""
        let textFontFamily = extendedProps[RDConstants.textFontFamily] as? String ?? ""
        let textSize = extendedProps[RDConstants.textSize] as? String ?? ""
        let buttonColor = extendedProps[RDInAppNotification.PayloadKey.buttonColor] as? String ?? ""
        let buttonTextColor = extendedProps[RDInAppNotification.PayloadKey.buttonTextColor] as? String ?? ""
        let buttonTextSize = extendedProps[RDConstants.buttonTextSize] as? String ?? ""
        let buttonFontFamily = extendedProps[RDConstants.buttonFontFamily] as? String ?? ""
        let emailPermitTextSize = extendedProps[RDConstants.emailPermitTextSize] as? String ?? ""
        let emailPermitTextUrl = extendedProps[RDConstants.emailPermitTextUrl] as? String ?? ""
        let consentTextSize = extendedProps[RDConstants.consentTextSize] as? String ?? ""
        let consentTextUrl = extendedProps[RDConstants.consentTextUrl] as? String ?? ""
        let closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? "black"
        let backgroundColor = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        
        let titleCustomFontFamilyIos = extendedProps[RDConstants.titleCustomFontFamilyIos] as? String ?? ""
        let textCustomFontFamilyIos = extendedProps[RDConstants.textCustomFontFamilyIos] as? String ?? ""
        let buttonCustomFontFamilyIos = extendedProps[RDConstants.buttonCustomFontFamilyIos] as? String ?? ""
        
        let impression = report[RDConstants.impression] as? String ?? ""
        let click = report[RDConstants.click] as? String ?? ""
        let mailReport = TargetingActionReport(impression: impression, click: click)
        let extendedProperties = MailSubscriptionExtendedProps(titleTextColor: titleTextColor,
                                                               titleFontFamily: titleFontFamily,
                                                               titleTextSize: titleTextSize,
                                                               textColor: textColor,
                                                               textFontFamily: textFontFamily,
                                                               textSize: textSize,
                                                               buttonColor: buttonColor,
                                                               buttonTextColor: buttonTextColor,
                                                               buttonTextSize: buttonTextSize,
                                                               buttonFontFamily: buttonFontFamily,
                                                               emailPermitTextSize: emailPermitTextSize,
                                                               emailPermitTextUrl: emailPermitTextUrl,
                                                               consentTextSize: consentTextSize,
                                                               consentTextUrl: consentTextUrl,
                                                               closeButtonColor: ButtonColor(rawValue: closeButtonColor) ?? ButtonColor.black,
                                                               backgroundColor: backgroundColor,titleCustomFontFamilyIos:titleCustomFontFamilyIos,textCustomFontFamilyIos:textCustomFontFamilyIos,buttonCustomFontFamilyIos:buttonCustomFontFamilyIos)

        let mailModel = MailSubscriptionModel(auth: auth,
                                              title: title,
                                              message: message,
                                              actid: actid,
                                              type: type,
                                              placeholder: placeholder,
                                              buttonTitle: buttonText,
                                              consentText: consentText,
                                              successMessage: successMsg,
                                              invalidEmailMessage: invalidMsg,
                                              emailPermitText: emailPermitText,
                                              extendedProps: extendedProperties,
                                              checkConsentMessage: checkConsent,
                                              report: mailReport)
        return convertJsonToEmailViewModel(emailForm: mailModel)
    }
    
    private func parseDrawer(_ drawer: [String: Any?]) -> DrawerServiceModel? {
        
        guard let actionData = drawer[RDConstants.actionData] as? [String: Any] else { return nil }
        var sideBarServiceModel = DrawerServiceModel(targetingActionType: .drawer)
        sideBarServiceModel.actId = drawer[RDConstants.actid] as? Int ?? 0
        sideBarServiceModel.title = drawer[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        
        //actionData
        sideBarServiceModel.shape = actionData[RDConstants.shape] as? String ?? ""
        sideBarServiceModel.pos = actionData[RDConstants.position] as? String ?? ""
        sideBarServiceModel.contentMinimizedImage  = actionData[RDConstants.contentMinimizedImage] as? String ?? ""
        sideBarServiceModel.contentMinimizedText = actionData[RDConstants.contentMinimizedText] as? String ?? ""
        sideBarServiceModel.contentMaximizedImage = actionData[RDConstants.contentMaximizedImage] as? String ?? ""
        sideBarServiceModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        sideBarServiceModel.iosLnk = actionData[RDConstants.iosLnk] as? String ?? ""
        
        //extended Props
        sideBarServiceModel.contentMinimizedTextSize = extendedProps[RDConstants.contentMinimizedTextSize] as? String ?? ""
        sideBarServiceModel.contentMinimizedTextColor = extendedProps[RDConstants.contentMinimizedTextColor] as? String ?? ""
        sideBarServiceModel.contentMinimizedFontFamily = extendedProps[RDConstants.contentMinimizedFontFamily] as? String ?? ""
        sideBarServiceModel.contentMinimizedCustomFontFamilyIos = extendedProps[RDConstants.contentMinimizedCustomFontFamilyIos] as? String ?? ""
        sideBarServiceModel.contentMinimizedTextOrientation = extendedProps[RDConstants.contentMinimizedTextOrientation] as? String ?? ""
        sideBarServiceModel.contentMinimizedBackgroundImage = extendedProps[RDConstants.contentMinimizedBackgroundImage] as? String ?? ""
        sideBarServiceModel.contentMinimizedBackgroundColor = extendedProps[RDConstants.contentMinimizedBackgroundColor] as? String ?? ""
        sideBarServiceModel.contentMinimizedArrowColor = extendedProps[RDConstants.contentMinimizedArrowColor] as? String ?? ""
        sideBarServiceModel.contentMaximizedBackgroundImage = extendedProps[RDConstants.contentMaximizedBackgroundImage] as? String ?? ""
        sideBarServiceModel.contentMaximizedBackgroundColor = extendedProps[RDConstants.contentMaximizedBackgroundColor] as? String ?? ""
    

        return sideBarServiceModel
    }
    


    private func parseScratchToWin(_ scratchToWin: [String: Any?]) -> ScratchToWinModel? {
        guard let actionData = scratchToWin[RDConstants.actionData] as? [String: Any] else { return nil }
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        let actid = scratchToWin[RDConstants.actid] as? Int ?? 0
        let auth = actionData[RDConstants.authentication] as? String ?? ""
        let hasMailForm = actionData[RDConstants.mailSubscription] as? Bool ?? false
        let scratchColor = actionData[RDConstants.scratchColor] as? String ?? "000000"
        let waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        let promotionCode = actionData[RDConstants.code] as? String ?? ""
        let sendMail = actionData[RDConstants.sendEmail] as? Bool ?? false
        let copyButtonText = actionData[RDConstants.copybuttonLabel] as? String ?? ""
        let img = actionData[RDConstants.img] as? String ?? ""
        let title = actionData[RDConstants.contentTitle] as? String ?? ""
        let message = actionData[RDConstants.contentBody] as? String ?? ""
        // Email parameters
        var mailPlaceholder: String?
        var mailButtonTxt: String?
        var consentText: String?
        var invalidEmailMsg: String?
        var successMsg: String?
        var emailPermitTxt: String?
        var checkConsentMsg: String?

        if let mailForm = actionData[RDConstants.sctwMailSubscriptionForm] as? [String: Any] {
            mailPlaceholder = mailForm[RDConstants.placeholder] as? String
            mailButtonTxt = mailForm[RDConstants.buttonLabel] as? String
            consentText = mailForm[RDConstants.consentText] as? String
            invalidEmailMsg = mailForm[RDConstants.invalidEmailMessage] as? String
            successMsg = mailForm[RDConstants.successMessage] as? String
            emailPermitTxt = mailForm[RDConstants.emailPermitText] as? String
            checkConsentMsg = mailForm[RDConstants.checkConsentMessage] as? String
        }

        // extended props
        let titleTextColor = extendedProps[RDConstants.contentTitleTextColor] as? String
        let titleFontFamily = extendedProps[RDConstants.contentTitleFontFamily] as? String
        let titleTextSize = extendedProps[RDConstants.contentTitleTextSize] as? String
        let messageTextColor = extendedProps[RDConstants.contentBodyTextColor] as? String
        let messageTextSize = extendedProps[RDConstants.contentBodyTextSize] as? String
        let messageTextFontFamily = extendedProps[RDConstants.contentBodyTextFontFamily] as? String
        let mailButtonColor = extendedProps[RDConstants.button_color] as? String
        let mailButtonTextColor = extendedProps[RDConstants.button_text_color] as? String
        let mailButtonFontFamily = extendedProps[RDConstants.buttonFontFamily] as? String
        let mailButtonTextSize = extendedProps[RDConstants.buttonTextSize] as? String
        let promocodeTextColor = extendedProps[RDConstants.promocodeTextColor] as? String
        let promocodeFontFamily = extendedProps[RDConstants.promocodeFontFamily] as? String
        let promocodeTextSize = extendedProps[RDConstants.promocodeTextSize] as? String
        let copyButtonColor = extendedProps[RDConstants.copybuttonColor] as? String
        let copyButtonTextColor = extendedProps[RDConstants.copybuttonTextColor] as? String
        let copyButtonFontFamily = extendedProps[RDConstants.copybuttonFontFamily] as? String
        let copyButtonTextSize = extendedProps[RDConstants.copybuttonTextSize] as? String
        let emailPermitTextSize = extendedProps[RDConstants.emailPermitTextSize] as? String
        let emailPermitTextUrl = extendedProps[RDConstants.emailPermitTextUrl] as? String
        let consentTextSize = extendedProps[RDConstants.consentTextSize] as? String
        let consentTextUrl = extendedProps[RDConstants.consentTextUrl] as? String
        let closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String
        let backgroundColor = extendedProps[RDConstants.backgroundColor] as? String

        let contentTitleCustomFontFamilyIos = extendedProps[RDConstants.contentTitleCustomFontFamilyIos] as? String ?? ""
        let contentBodyCustomFontFamilyIos = extendedProps[RDConstants.contentBodyCustomFontFamilyIos] as? String ?? ""
        let buttonCustomFontFamilyIos = extendedProps[RDConstants.buttonCustomFontFamilyIos] as? String ?? ""
        let promocodeCustomFontFamilyIos = extendedProps[RDConstants.promocodeCustomFontFamilyIos] as? String ?? ""
        let copybuttonCustomFontFamilyIos = extendedProps[RDConstants.copybuttonCustomFontFamilyIos] as? String

        
        var click = ""
        var impression = ""
        if let report = actionData[RDConstants.report] as? [String: Any] {
            click = report[RDConstants.click] as? String ?? ""
            impression = report[RDConstants.impression] as? String ?? ""
        }
        let rep = TargetingActionReport(impression: impression, click: click)

        return ScratchToWinModel(type: .scratchToWin,
                                 actid: actid,
                                 auth: auth,
                                 hasMailForm: hasMailForm,
                                 scratchColor: scratchColor,
                                 waitingTime: waitingTime,
                                 promocode: promotionCode,
                                 sendMail: sendMail,
                                 copyButtonText: copyButtonText,
                                 imageUrlString: img,
                                 title: title,
                                 message: message,
                                 mailPlaceholder: mailPlaceholder,
                                 mailButtonText: mailButtonTxt,
                                 consentText: consentText,
                                 invalidEmailMsg: invalidEmailMsg,
                                 successMessage: successMsg,
                                 emailPermitText: emailPermitTxt,
                                 checkConsentMessage: checkConsentMsg,
                                 titleTextColor: titleTextColor,
                                 titleFontFamily: titleFontFamily,
                                 titleTextSize: titleTextSize,
                                 messageTextColor: messageTextColor,
                                 messageFontFamily: messageTextFontFamily,
                                 messageTextSize: messageTextSize,
                                 mailButtonColor: mailButtonColor,
                                 mailButtonTextColor: mailButtonTextColor,
                                 mailButtonFontFamily: mailButtonFontFamily,
                                 mailButtonTextSize: mailButtonTextSize,
                                 promocodeTextColor: promocodeTextColor,
                                 promocodeTextFamily: promocodeFontFamily,
                                 promocodeTextSize: promocodeTextSize,
                                 copyButtonColor: copyButtonColor,
                                 copyButtonTextColor: copyButtonTextColor,
                                 copyButtonFontFamily: copyButtonFontFamily,
                                 copyButtonTextSize: copyButtonTextSize,
                                 emailPermitTextSize: emailPermitTextSize,
                                 emailPermitUrl: emailPermitTextUrl,
                                 consentTextSize: consentTextSize,
                                 consentUrl: consentTextUrl,
                                 closeButtonColor: closeButtonColor,
                                 backgroundColor: backgroundColor,
                                 report: rep,
                                 contentTitleCustomFontFamilyIos:contentTitleCustomFontFamilyIos,
                                 contentBodyCustomFontFamilyIos:contentBodyCustomFontFamilyIos,
                                 buttonCustomFontFamilyIos:buttonCustomFontFamilyIos,
                                 promocodeCustomFontFamilyIos:promocodeCustomFontFamilyIos,
                                 copybuttonCustomFontFamilyIos:copybuttonCustomFontFamilyIos)
    }

    private func convertJsonToEmailViewModel(emailForm: MailSubscriptionModel) -> MailSubscriptionViewModel {
        var parsedConsent: ParsedPermissionString?
        if let consent = emailForm.consentText, !consent.isEmpty {
            parsedConsent = consent.parsePermissionText()
        }
        let parsedPermit = emailForm.emailPermitText.parsePermissionText()
        let titleFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.titleFontFamily,
                                                          fontSize: emailForm.extendedProps.titleTextSize,
                                                          style: .title2,customFont: emailForm.extendedProps.titleCustomFontFamilyIos)
        let messageFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.textFontFamily,
                                                            fontSize: emailForm.extendedProps.textSize,
                                                            style: .body,customFont: emailForm.extendedProps.textCustomFontFamilyIos)
        let buttonFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.buttonFontFamily,
                                                           fontSize: emailForm.extendedProps.buttonTextSize,
                                                           style: .title2,customFont: emailForm.extendedProps.buttonCustomFontFamilyIos)
        let closeButtonColor = getCloseButtonColor(from: emailForm.extendedProps.closeButtonColor)
        let titleColor = UIColor(hex: emailForm.extendedProps.titleTextColor) ?? .white
        let textColor = UIColor(hex: emailForm.extendedProps.textColor) ?? .white
        let backgroundColor = UIColor(hex: emailForm.extendedProps.backgroundColor) ?? .black
        let emailPermitUrl = URL(string: emailForm.extendedProps.emailPermitTextUrl)
        let consentUrl = URL(string: emailForm.extendedProps.consentTextUrl)
        let buttonTextColor = UIColor(hex: emailForm.extendedProps.buttonTextColor) ?? .white
        let buttonColor = UIColor(hex: emailForm.extendedProps.buttonColor) ?? .black
        let permitTextSize = (Int(emailForm.extendedProps.emailPermitTextSize) ?? 0) + 6
        let consentTextSize = (Int(emailForm.extendedProps.consentTextSize) ?? 0) + 6
        let viewModel = MailSubscriptionViewModel(targetingActionType: .mailSubscriptionForm,
                                                  auth: emailForm.auth,
                                                  actId: emailForm.actid,
                                                  type: emailForm.type,
                                                  title: emailForm.title,
                                                  message: emailForm.message,
                                                  placeholder: emailForm.placeholder,
                                                  buttonTitle: emailForm.buttonTitle,
                                                  consentText: parsedConsent,
                                                  permitText: parsedPermit,
                                                  successMessage: emailForm.successMessage,
                                                  invalidEmailMessage: emailForm.invalidEmailMessage,
                                                  checkConsentMessage: emailForm.checkConsentMessage,
                                                  titleFont: titleFont,
                                                  messageFont: messageFont,
                                                  buttonFont: buttonFont,
                                                  buttonTextColor: buttonTextColor,
                                                  buttonColor: buttonColor,
                                                  emailPermitUrl: emailPermitUrl,
                                                  consentUrl: consentUrl,
                                                  closeButtonColor: closeButtonColor,
                                                  titleColor: titleColor,
                                                  textColor: textColor,
                                                  backgroundColor: backgroundColor,
                                                  permitTextSize: permitTextSize,
                                                  consentTextSize: consentTextSize,
                                                  report: emailForm.report)
        return viewModel
    }

    func getCloseButtonColor(from buttonColor: ButtonColor) -> UIColor {
        if buttonColor == .white {
            return .white
        } else {
            return .black
        }
    }

    // MARK: - Favorites

    func getFavorites(rdUser: RDUser, actionId: Int? = nil,
                      completion: @escaping ((_ response: RDFavoriteAttributeActionResponse) -> Void)) {

        var props = Properties()
        props[RDConstants.organizationIdKey] = self.rdProfile.organizationId
        props[RDConstants.profileIdKey] = self.rdProfile.profileId
        props[RDConstants.cookieIdKey] = rdUser.cookieId
        props[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RDConstants.tokenIdKey] = rdUser.tokenId
        props[RDConstants.appidKey] = rdUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        props[RDConstants.actionType] = RDConstants.favoriteAttributeAction
        props[RDConstants.actionId] = actionId == nil ? nil : String(actionId!)
        
        
        props[RDConstants.nrvKey] = String(rdUser.nrv)
        props[RDConstants.pvivKey] = String(rdUser.pviv)
        props[RDConstants.tvcKey] = String(rdUser.tvc)
        props[RDConstants.lvtKey] = rdUser.lvt

        for (key, value) in RDPersistence.readTargetParameters() {
           if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
               props[key] = value
           }
        }

        RDRequest.sendMobileRequest(properties: props, headers: Properties(), completion: { (result: [String: Any]?, error: RDError?, _: String?) in
            completion(self.parseFavoritesResponse(result, error))
        })
    }

    private func parseFavoritesResponse(_ result: [String: Any]?,
                                        _ error: RDError?) -> RDFavoriteAttributeActionResponse {
        var favoritesResponse = [RDFavoriteAttribute: [String]]()
        var errorResponse: RDError?
        if let error = error {
            errorResponse = error
        } else if let res = result {
            if let favoriteAttributeActions = res[RDConstants.favoriteAttributeAction] as? [[String: Any?]] {
                for favoriteAttributeAction in favoriteAttributeActions {
                    if let actiondata = favoriteAttributeAction[RDConstants.actionData] as? [String: Any?] {
                        if let favorites = actiondata[RDConstants.favorites] as? [String: [String]?] {
                            for favorite in favorites {
                                if let favoriteAttribute = RDFavoriteAttribute(rawValue: favorite.key),
                                   let favoriteValues = favorite.value {
                                    favoritesResponse[favoriteAttribute].mergeStringArray(favoriteValues)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            errorResponse = RDError.noData
        }
        return RDFavoriteAttributeActionResponse(favorites: favoritesResponse, error: errorResponse)
    }

    // MARK: - Story

    var rdStoryHomeViewControllers = [String: RDStoryHomeViewController]()
    var rdStoryHomeViews = [String: RDStoryHomeView]()

    func getStories(rdUser: RDUser, guid: String, actionId: Int? = nil, completion: @escaping ((_ response: RDStoryActionResponse) -> Void)) {

        var props = Properties()
        props[RDConstants.organizationIdKey] = rdProfile.organizationId
        props[RDConstants.profileIdKey] = rdProfile.profileId
        props[RDConstants.cookieIdKey] = rdUser.cookieId
        props[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RDConstants.tokenIdKey] = rdUser.tokenId
        props[RDConstants.appidKey] = rdUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        props[RDConstants.actionType] = RDConstants.story
        props[RDConstants.channelKey] = rdProfile.channel
        props[RDConstants.actionId] = actionId == nil ? nil : String(actionId!)
        
        props[RDConstants.nrvKey] = String(rdUser.nrv)
        props[RDConstants.pvivKey] = String(rdUser.pviv)
        props[RDConstants.tvcKey] = String(rdUser.tvc)
        props[RDConstants.lvtKey] = rdUser.lvt

        for (key, value) in RDPersistence.readTargetParameters() {
           if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
               props[key] = value
           }
        }

        RDRequest.sendMobileRequest(properties: props, headers: Properties(), completion: {(result: [String: Any]?, error: RDError?, guid: String?) in
            completion(self.parseStories(result, error, guid))
        }, guid: guid)
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    // TO_DO: burada storiesResponse kısmı değiştirilmeli. aynı requestte birden fazla story action'ı gelebilir.
    private func parseStories(_ result: [String: Any]?, _ error: RDError?, _ guid: String?) -> RDStoryActionResponse {
        var storiesResponse = [RDStoryAction]()
        var errorResponse: RDError?
        if let error = error {
            errorResponse = error
        } else if let res = result {
            if let storyActions = res[RDConstants.story] as? [[String: Any?]] {
                var relatedDigitalStories = [RDStory]()
                for storyAction in storyActions {
                    if let actionId = storyAction[RDConstants.actid] as? Int,
                       let actiondata = storyAction[RDConstants.actionData] as? [String: Any?],
                       let templateString = actiondata[RDConstants.taTemplate] as? String,
                       let template = RDStoryTemplate.init(rawValue: templateString) {
                        if let stories = actiondata[RDConstants.stories] as? [[String: Any]] {
                            for story in stories {
                                if template == .skinBased {
                                    var storyItems = [RDStoryItem]()
                                    if let items = story[RDConstants.items] as? [[String: Any]] {
                                        for item in items {
                                            storyItems.append(parseStoryItem(item))
                                        }
                                        if storyItems.count > 0 {
                                            relatedDigitalStories.append(RDStory(title: story[RDConstants.title]
                                                                                    as? String,
                                            smallImg: story[RDConstants.thumbnail] as? String,
                                            link: story[RDConstants.link] as? String, items: storyItems, actid: actionId))
                                        }
                                    }
                                } else {
                                    relatedDigitalStories.append(RDStory(title: story[RDConstants.title]
                                                                            as? String,
                                    smallImg: story[RDConstants.smallImg] as? String,
                                    link: story[RDConstants.link] as? String, actid: actionId))
                                }
                            }
                            let (clickQueryItems, impressionQueryItems)
                                = parseStoryReport(actiondata[RDConstants.report] as? [String: Any?])
                            if stories.count > 0 {
                                storiesResponse.append(RDStoryAction(actionId: actionId,
                                                                           storyTemplate: template,
                                                                           stories: relatedDigitalStories,
                                                                           clickQueryItems: clickQueryItems,
                                                                           impressionQueryItems: impressionQueryItems,
                        extendedProperties: parseStoryExtendedProps(actiondata[RDConstants.extendedProps]
                                                                                                    as? String)))
                            }
                        }
                    }
                }
            }
        } else {
            errorResponse = RDError.noData
        }
        return RDStoryActionResponse(storyActions: storiesResponse, error: errorResponse, guid: guid)
    }

    private func parseStoryReport(_ report: [String: Any?]?) -> (Properties, Properties) {
        var clickItems = Properties()
        var impressionItems = Properties()
        // clickItems[VisilabsConstants.domainkey] =  "\(self.visilabsProfile.dataSource)_IOS" // TO_DO: OM.domain ne için gerekiyor?
        if let rep = report {
            if let click = rep[RDConstants.click] as? String {
                let qsArr = click.components(separatedBy: "&")
                for queryItem in qsArr {
                    let queryItemComponents = queryItem.components(separatedBy: "=")
                    if queryItemComponents.count == 2 {
                        clickItems[queryItemComponents[0]] = queryItemComponents[1]
                    }
                }
            }
            if let impression = rep[RDConstants.impression] as? String {
                let qsArr = impression.components(separatedBy: "&")
                for queryItem in qsArr {
                    let queryItemComponents = queryItem.components(separatedBy: "=")
                    if queryItemComponents.count == 2 {
                        impressionItems[queryItemComponents[0]] = queryItemComponents[1]
                    }
                }
            }

        }
        return (clickItems, impressionItems)
    }

    private func parseStoryItem(_ item: [String: Any]) -> RDStoryItem {
        let fileType = (item[RDConstants.fileType] as? String) ?? "photo"
        let fileSrc = (item[RDConstants.fileSrc] as? String) ?? ""
        let targetUrl = (item[RDConstants.targetUrl]  as? String) ?? ""
        let buttonText = (item[RDConstants.buttonText]  as? String) ?? ""
        var displayTime = 3
        if let dTime = item[RDConstants.displayTime] as? Int, dTime > 0 {
            displayTime = dTime
        }
        var buttonTextColor = UIColor.white
        var buttonColor = UIColor.black
        if let buttonTextColorString = item[RDConstants.buttonTextColor] as? String {
            if buttonTextColorString.starts(with: "rgba") {
                if let btColor =  UIColor.init(rgbaString: buttonTextColorString) {
                    buttonTextColor = btColor
                }
            } else {
                if let btColor = UIColor.init(hex: buttonTextColorString) {
                    buttonTextColor = btColor
                }
            }
        }
        if let buttonColorString = item[RDConstants.buttonColor] as? String {
            if buttonColorString.starts(with: "rgba") {
                if let bColor =  UIColor.init(rgbaString: buttonColorString) {
                    buttonColor = bColor
                }
            } else {
                if let bColor = UIColor.init(hex: buttonColorString) {
                    buttonColor = bColor
                }
            }
        }
        let relatedDigitalStoryItem = RDStoryItem(fileType: fileType,
                                                  displayTime: displayTime,
                                                  fileSrc: fileSrc,
                                                  targetUrl: targetUrl,
                                                  buttonText: buttonText,
                                                  buttonTextColor: buttonTextColor,
                                                  buttonColor: buttonColor)
        return relatedDigitalStoryItem
    }

    // swiftlint:disable cyclomatic_complexity
    private func parseStoryExtendedProps(_ extendedPropsString: String?) -> RDStoryActionExtendedProperties {
        let props = RDStoryActionExtendedProperties()
        if let propStr = extendedPropsString, let extendedProps = propStr.urlDecode().convertJsonStringToDictionary() {
            if let imageBorderWidthString = extendedProps[RDConstants.storylbImgBorderWidth] as? String,
               let imageBorderWidth = Int(imageBorderWidthString) {
                props.imageBorderWidth = imageBorderWidth
            }
            if let imageBorderRadiusString = extendedProps[RDConstants.storylbImgBorderRadius] as? String
                ?? extendedProps[RDConstants.storyzImgBorderRadius] as? String,
               let imageBorderRadius = Double(imageBorderRadiusString.trimmingCharacters(in:
                                                                        CharacterSet(charactersIn: "%"))) {
                props.imageBorderRadius = imageBorderRadius / 100.0
            }
            let storyzLabelColor = extendedProps[RDConstants.storyzLabelColor] as? String ?? ""
            props.storyzLabelColor = storyzLabelColor
            storyCustomVariables.shared.storyzLabelColor = storyzLabelColor

            let fontFamily = extendedProps[RDConstants.fontFamily] as? String ?? ""
            props.fontFamily = fontFamily
            storyCustomVariables.shared.fontFamily = fontFamily


            let customFontFamilyIos = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
            props.customFontFamilyIos = customFontFamilyIos
            storyCustomVariables.shared.customFontFamilyIos = customFontFamilyIos

            
            if let imageBorderColorString = extendedProps[RDConstants.storylbImgBorderColor] as? String
                ?? extendedProps[RDConstants.storyzimgBorderColor] as? String {
                if imageBorderColorString.starts(with: "rgba") {
                    if let imageBorderColor =  UIColor.init(rgbaString: imageBorderColorString) {
                        props.imageBorderColor = imageBorderColor
                    }
                } else {
                    if let imageBorderColor = UIColor.init(hex: imageBorderColorString) {
                        props.imageBorderColor = imageBorderColor
                    }
                }
            }
            if let labelColorString = extendedProps[RDConstants.storylbLabelColor] as? String {
                if labelColorString.starts(with: "rgba") {
                    if let labelColor =  UIColor.init(rgbaString: labelColorString) {
                        props.labelColor = labelColor
                    }
                } else {
                    if let labelColor = UIColor.init(hex: labelColorString) {
                        props.labelColor = labelColor
                    }
                }
            }
            if let boxShadowString = extendedProps[RDConstants.storylbImgBoxShadow] as? String,
               boxShadowString.count > 0 {
                props.imageBoxShadow = true
            }

            if let moveEnd = extendedProps[RDConstants.moveShownToEnd] as? String, moveEnd.lowercased() == "false" {
                props.moveShownToEnd = false
            } else {
                props.moveShownToEnd = true
            }
        }
        return props
    }

}
