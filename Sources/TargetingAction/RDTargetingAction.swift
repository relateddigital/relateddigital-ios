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
        notificationsInstance = RDInAppNotifications(lock: lock)
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
                       let notification = RDInAppNotification(JSONObject: rawNotif), notification.displayType != RDConstants.inline {
                        notifications.append(notification)
                    }
                }
            }
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        RDLogger.info("in app notification check: \(notifications.count) found." +
            " actid's: \(notifications.map({ String($0.actId) }).joined(separator: ","))")

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

        props[RDConstants.actionType] = "\(RDConstants.mailSubscriptionForm)~\(RDConstants.spinToWin)~\(RDConstants.scratchToWin)~\(RDConstants.productStatNotifier)~\(RDConstants.drawer)~\(RDConstants.gamification)~\(RDConstants.findToWin)~\(RDConstants.shakeToWin)~\(RDConstants.giftBox)~\(RDConstants.chooseFavorite)~\(RDConstants.slotMachine)~\(RDConstants.mobileCustomActions)~\(RDConstants.apprating)~\(RDConstants.clawMachine)~\(RDConstants.MultipleChoiceSurvey)~\(RDConstants.NotificationBell)~\(RDConstants.CountdownTimerBanner)"

        for (key, value) in RDPersistence.readTargetParameters() {
            if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                props[key] = value
            }
        }

        props[RDConstants.pushPermitPermissionReqKey] = RDConstants.pushPermitStatus

        RDRequest.sendMobileRequest(properties: props, headers: prepareHeaders(rdUser), completion: { (result: [String: Any]?, _: RDError?, _: String?) in
            guard let result = result else {
                semaphore.signal()
                completion(nil)
                return
            }
            targetingActionViewModel = self.parseTargetingAction(result)

            if targetingActionViewModel?.targetingActionType == .spinToWin {
                RDRequest.sendSpinToWinScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .giftCatch {
                RDRequest.sendGiftCatchScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .findToWin {
                RDRequest.sendFindToWinScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .giftBox {
                RDRequest.sendGiftBoxScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .chooseFavorite {
                RDRequest.sendChooseFavoriteScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .slotMachine {
                RDRequest.sendJackpotScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            }  else if targetingActionViewModel?.targetingActionType == .MultipleChoiceSurvey {
                RDRequest.sendPollScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else if targetingActionViewModel?.targetingActionType == .clawMachine {
                RDRequest.sendClawMachineScriptRequest(completion: { (result: String?, _: RDError?) in
                    if let result = result {
                        targetingActionViewModel?.jsContent = result
                    } else {
                        targetingActionViewModel = nil
                    }
                    semaphore.signal()
                })
            } else {
                semaphore.signal()
            }
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
        } else if let timerBanner = result[RDConstants.CountdownTimerBanner] as? [[String: Any?]], let tmrbnnr = timerBanner.first {
            return parseTimerBanner(tmrbnnr)
        }else if let downHsViewArr = result[RDConstants.downHsView] as? [[String: Any?]], let downHs = downHsViewArr.first {
            return parseDownHsView(downHs)
        } else if let gamification = result[RDConstants.gamification] as? [[String: Any?]], let gamifi = gamification.first {
            return parseGiftCatch(gamifi)
        } else if let shakeToWin = result[RDConstants.shakeToWin] as? [[String: Any?]], let shakeToWn = shakeToWin.first {
            return parseShakeToWin(shakeToWn)
        } else if let findToWin = result[RDConstants.findToWin] as? [[String: Any?]], let findTown = findToWin.first {
            return parseFindToWin(findTown)
        } else if let giftBox = result[RDConstants.giftBox] as? [[String: Any?]], let giftBox = giftBox.first {
            return parseGiftBox(giftBox)
        } else if let chooseFavorite = result[RDConstants.chooseFavorite] as? [[String: Any?]], let chooseFavorite = chooseFavorite.first {
            return parseChooseFavorite(chooseFavorite)
        } else if let jackpot = result[RDConstants.slotMachine] as? [[String: Any?]], let jackpot = jackpot.first {
            return parseJackpot(jackpot)
        } else if let survey = result[RDConstants.MultipleChoiceSurvey] as? [[String: Any?]], let survey = survey.first {
            return parsePoll(survey)
        } else if let clawMachine = result[RDConstants.clawMachine] as? [[String: Any?]], let clawMachine = clawMachine.first {
            return parseClawMachine(clawMachine)
        } else if let customWeb = result[RDConstants.mobileCustomActions] as? [[String: Any?]], let customWeb = customWeb.first {
            return parseCustomWebview(customWeb)
        } else if let notBell = result[RDConstants.NotificationBell] as? [[String: Any?]], let notifBell = notBell.first {
            return parseNotificationBell(notifBell)
        } else if let inappRating = result[RDConstants.apprating] as? [[String: Any?]], let inappRating = inappRating.first {
            return parseInappRating(inappRating)
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

    private func parseShakeToWin(_ shakeToWin: [String: Any?]) -> ShakeToWinViewModel? {
        guard let actionData = shakeToWin[RDConstants.actionData] as? [String: Any] else { return nil }
        var shakeToWinModel = ShakeToWinViewModel(targetingActionType: .shakeToWin)
        shakeToWinModel.actId = shakeToWin[RDConstants.actid] as? Int ?? 0
        shakeToWinModel.title = shakeToWin[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        guard let report = actionData[RDConstants.report] as? [String: Any] else { return nil }
        shakeToWinModel.auth = actionData[RDConstants.authentication] as? String ?? ""
        shakeToWinModel.backGroundImage = extendedProps[RDConstants.backgroundImage] as? String

        let impression = report[RDConstants.impression] as? String ?? ""
        let click = report[RDConstants.click] as? String ?? ""
        let mailReport = shakeToWinReport(impression: impression, click: click)
        shakeToWinModel.report = mailReport

        var mailFormPage = MailSubscriptionModelGamification()
        if let mailForm = actionData[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            mailFormPage.placeholder = mailForm[RDConstants.placeholder] as? String ?? ""
            mailFormPage.buttonTitle = mailForm[RDConstants.buttonLabel] as? String ?? ""
            mailFormPage.consentText = mailForm[RDConstants.consentText] as? String
            mailFormPage.invalidEmailMessage = mailForm[RDConstants.invalidEmailMessage] as? String ?? ""
            mailFormPage.successMessage = mailForm[RDConstants.successMessage] as? String ?? ""
            mailFormPage.emailPermitText = mailForm[RDConstants.emailPermitText] as? String ?? ""
            mailFormPage.checkConsentMessage = mailForm[RDConstants.checkConsentMessage] as? String ?? ""
            mailFormPage.title = mailForm[RDConstants.title] as? String ?? ""
            mailFormPage.message = mailForm[RDConstants.message] as? String ?? ""
        }

        shakeToWinModel.mailForm = mailFormPage

        var mailExtendedProps = MailSubscriptionExtendedPropsGamification()

        if let mailFormExtended = extendedProps[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            mailExtendedProps.textColor = mailFormExtended[RDConstants.textColor] as? String ?? ""
            mailExtendedProps.textSize = mailFormExtended[RDConstants.textSize] as? String ?? ""
            mailExtendedProps.titleTextSize = mailFormExtended[RDConstants.titleTextSize] as? String ?? ""
            mailExtendedProps.buttonColor = mailFormExtended[RDConstants.button_color] as? String ?? ""
            mailExtendedProps.buttonTextColor = mailFormExtended[RDConstants.button_text_color] as? String ?? ""
            mailExtendedProps.buttonTextSize = mailFormExtended[RDConstants.buttonTextSize] as? String ?? ""
            mailExtendedProps.emailPermitTextSize = mailFormExtended[RDConstants.emailpermitTextSize] as? String ?? ""
            mailExtendedProps.emailPermitTextUrl = mailFormExtended[RDConstants.emailpermitTextUrl] as? String ?? ""
            mailExtendedProps.consentTextSize = mailFormExtended[RDConstants.consentTextSize] as? String ?? ""
            mailExtendedProps.consentTextUrl = mailFormExtended[RDConstants.consentTextUrl] as? String ?? ""
            mailExtendedProps.titleFontFamily = mailFormExtended[RDConstants.titleFontFamily] as? String ?? ""
        }

        shakeToWinModel.mailExtendedProps = mailExtendedProps

        var firstPage = ShakeToWinFirstPage()
        if let gamificationRules = actionData[RDConstants.gamificationRules] as? [String: Any] {
            firstPage.image = gamificationRules[RDConstants.backgroundImage] as? String ?? ""
            firstPage.buttonText = gamificationRules[RDConstants.buttonLabel] as? String ?? ""
        }

        if let gameficationRuleExtended = extendedProps[RDConstants.gamificationRules] as? [String: Any] {
            firstPage.buttonBgColor = UIColor(hex: gameficationRuleExtended[RDConstants.button_color] as? String ?? "")
            firstPage.buttonTextColor = UIColor(hex: gameficationRuleExtended[RDConstants.button_text_color] as? String ?? "")
            firstPage.buttonFont = RDHelper.getFont(fontFamily: extendedProps[RDConstants.fontFamily] as? String ?? "", fontSize: gameficationRuleExtended[RDConstants.buttonTextSize] as? String ?? "", style: .title2, customFont: extendedProps[RDConstants.customFontFamilyIos] as? String ?? "")
        }
        firstPage.backgroundColor = UIColor(hex: extendedProps[RDConstants.backgroundColor] as? String ?? "")

        shakeToWinModel.firstPage = firstPage

        var secondPage = ShakeToWinSecondPage()
        if let gameElements = actionData[RDConstants.gameElements] as? [String: Any] {
            secondPage.videoURL = URL(string: gameElements[RDConstants.videoUrl] as? String ?? "")
            secondPage.waitSeconds = gameElements[RDConstants.videoUrl] as? Int ?? 5
            shakeToWinModel.soundUrl = gameElements[RDConstants.soundUrl] as? String ?? ""
        }
        secondPage.backGroundColor = UIColor(hex: extendedProps[RDConstants.backgroundColor] as? String ?? "")
        shakeToWinModel.secondPage = secondPage

        var thirdPage = ShakeToWinThirdPage()
        if let gameResultElements = actionData[RDConstants.gameResultElements] as? [String: Any] {
            thirdPage.title = gameResultElements[RDConstants.title] as? String ?? ""
            thirdPage.message = gameResultElements[RDConstants.message] as? String ?? ""
        }
        thirdPage.buttonText = actionData[RDConstants.copybuttonLabel] as? String
        thirdPage.iosLink = actionData[RDConstants.iosLnk] as? String
        thirdPage.staticCode = actionData[RDConstants.code] as? String

        if let gameficationResultElementExtended = extendedProps[RDConstants.gameResultElements] as? [String: Any] {
            thirdPage.titleColor = UIColor(hex: gameficationResultElementExtended[RDConstants.titleTextColor] as? String ?? "")
            thirdPage.titleFont = RDHelper.getFont(fontFamily: extendedProps[RDConstants.fontFamily] as? String ?? "", fontSize: gameficationResultElementExtended[RDConstants.titleTextSize] as? String ?? "", style: .title2, customFont: extendedProps[RDConstants.customFontFamilyIos] as? String ?? "")

            thirdPage.messageColor = UIColor(hex: gameficationResultElementExtended[RDConstants.textColor] as? String ?? "")
            thirdPage.messageFont = RDHelper.getFont(fontFamily: extendedProps[RDConstants.fontFamily] as? String ?? "", fontSize: gameficationResultElementExtended[RDConstants.textSize] as? String ?? "", style: .title2, customFont: extendedProps[RDConstants.customFontFamilyIos] as? String ?? "")
        }

        thirdPage.backgroundColor = UIColor(hex: extendedProps[RDConstants.backgroundColor] as? String ?? "")
        thirdPage.buttonBgColor = UIColor(hex: extendedProps[RDConstants.copybuttonColor] as? String ?? "")
        thirdPage.buttonTextColor = UIColor(hex: extendedProps[RDConstants.copybuttonTextColor] as? String ?? "")
        thirdPage.buttonFont = RDHelper.getFont(fontFamily: extendedProps[RDConstants.fontFamily] as? String ?? "", fontSize: extendedProps[RDConstants.copybuttonTextSize] as? String ?? "", style: .title2, customFont: extendedProps[RDConstants.customFontFamilyIos] as? String ?? "")

        shakeToWinModel.thirdPage = thirdPage

        shakeToWinModel.promocode_background_color = extendedProps[RDConstants.promocodeBackgroundColor] as? String ?? ""
        shakeToWinModel.promocode_text_color = extendedProps[RDConstants.promocodeTextColor] as? String ?? ""
        shakeToWinModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        shakeToWinModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        shakeToWinModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        shakeToWinModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""

        shakeToWinModel.closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? "black"

        if shakeToWinModel.promocode_banner_button_label?.count ?? 0 > 0 && shakeToWinModel.promocode_banner_text?.count ?? 0 > 0 {
            shakeToWinModel.bannercodeShouldShow = true
        } else {
            shakeToWinModel.bannercodeShouldShow = false
        }

        return shakeToWinModel
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
        let copyButtonFunction = actionData[RDConstants.copyButtonFunction] as? String ?? "copy"

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

        let redirectbuttonLabel = actionData[RDConstants.redirectbutton_label] as? String ?? ""
        let displaynameTextAlign = extendedProps[RDConstants.displayname_text_align] as? String ?? ""
        let redirectbuttonColor = extendedProps[RDConstants.redirectbutton_color] as? String ?? ""
        let redirectbuttonTextColor = extendedProps[RDConstants.redirectbutton_text_color] as? String ?? ""
        
        let waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0


        var sliceArray = [SpinToWinSliceViewModel]()

        for slice in slices {
            let displayName = slice[RDConstants.displayName] as? String ?? ""
            let color = slice[RDConstants.color] as? String ?? ""
            let code = slice[RDConstants.code] as? String ?? ""
            let type = slice[RDConstants.type] as? String ?? ""
            let isAvailable = slice[RDConstants.isAvailable] as? Bool ?? true
            let iosLink = slice[RDConstants.iosLink] as? String ?? ""
            let infotext = slice[RDConstants.infotext] as? String ?? ""
            let spinToWinSliceViewModel = SpinToWinSliceViewModel(displayName: displayName, color: color, code: code, type: type, isAvailable: isAvailable, iosLink: iosLink, infotext: infotext)
            sliceArray.append(spinToWinSliceViewModel)
        }

        let model = SpinToWinViewModel(targetingActionType: .spinToWin, actId: actid, auth: auth, promoAuth: promoAuth, type: type, title: title, message: message, placeholder: placeholder, buttonLabel: buttonLabel, consentText: consentText, emailPermitText: emailPermitText, successMessage: successMessage, invalidEmailMessage: invalidEmailMessage, checkConsentMessage: checkConsentMessage, promocodeTitle: promocodeTitle, copyButtonLabel: copybuttonLabel, mailSubscription: mailSubscription, sliceCount: sliceCount, slices: sliceArray, report: spinToWinReport, taTemplate: taTemplate, img: img, wheelSpinAction: wheelSpinAction, promocodesSoldoutMessage: promocodesSoldoutMessage, copyButtonFunction: copyButtonFunction, waitingTime: waitingTime, displaynameTextColor: displaynameTextColor, displaynameFontFamily: displaynameFontFamily, displaynameTextSize: displaynameTextSize, titleTextColor: titleTextColor, titleFontFamily: titleFontFamily, titleTextSize: titleTextSize, textColor: textColor, textFontFamily: textFontFamily, textSize: textSize, buttonColor: button_color, buttonTextColor: button_text_color, buttonFontFamily: buttonFontFamily, buttonTextSize: buttonTextSize, promocodeTitleTextColor: promocodeTitleTextColor, promocodeTitleFontFamily: promocodeTitleFontFamily, promocodeTitleTextSize: promocodeTitleTextSize, promocodeBackgroundColor: promocodeBackgroundColor, promocodeTextColor: promocodeTextColor, copybuttonColor: copybuttonColor, copybuttonTextColor: copybuttonTextColor, copybuttonFontFamily: copybuttonFontFamily, copybuttonTextSize: copybuttonTextSize, emailpermitTextSize: emailpermitTextSize, emailpermitTextUrl: emailpermitTextUrl, consentTextSize: consentTextSize, consentTextUrl: consentTextUrl, closeButtonColor: closeButtonColor, backgroundColor: backgroundColor, wheelBorderWidth: wheelBorderWidth, wheelBorderColor: wheelBorderColor, sliceDisplaynameFontFamily: sliceDisplaynameFontFamily, promocodesSoldoutMessageTextColor: promocodesSoldoutMessageTextColor, promocodesSoldoutMessageFontFamily: promocodesSoldoutMessageFontFamily, promocodesSoldoutMessageTextSize: promocodesSoldoutMessageTextSize, promocodesSoldoutMessageBackgroundColor: promocodesSoldoutMessageBackgroundColor, displaynameCustomFontFamilyIos: displaynameCustomFontFamilyIos, titleCustomFontFamilyIos: titleCustomFontFamilyIos, textCustomFontFamilyIos: textCustomFontFamilyIos, buttonCustomFontFamilyIos: buttonCustomFontFamilyIos, promocodeTitleCustomFontFamilyIos: promocodeTitleCustomFontFamilyIos, copybuttonCustomFontFamilyIos: copybuttonCustomFontFamilyIos, promocodesSoldoutMessageCustomFontFamilyIos: promocodesSoldoutMessageCustomFontFamilyIos, titlePosition: titlePosition, textPosition: textPosition, buttonPosition: buttonPosition, copybuttonPosition: copybuttonPosition, promocodeBannerText: promocodeBannerText, promocodeBannerTextColor: promocodeBannerTextColor, promocodeBannerBackgroundColor: promocodeBannerBackgroundColor, promocodeBannerButtonLabel: promocodeBannerButtonLabel, redirectbuttonLabel: redirectbuttonLabel, displaynameTextAlign: displaynameTextAlign, redirectbuttonColor: redirectbuttonColor, redirectbuttonTextColor: redirectbuttonTextColor)

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
        if let positionString = actionData[RDConstants.pos] as? String, let pos = RDProductStatNotifierPosition(rawValue: positionString) {
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
        downHsViewServiceModel.auth = actionData[RDConstants.authentication] as? String ?? ""

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

        // extended props
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
                                                               backgroundColor: backgroundColor, titleCustomFontFamilyIos: titleCustomFontFamilyIos, textCustomFontFamilyIos: textCustomFontFamilyIos, buttonCustomFontFamilyIos: buttonCustomFontFamilyIos)

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

        // actionData
        sideBarServiceModel.shape = actionData[RDConstants.shape] as? String ?? ""
        sideBarServiceModel.pos = actionData[RDConstants.position] as? String ?? ""
        sideBarServiceModel.contentMinimizedImage = actionData[RDConstants.contentMinimizedImage] as? String ?? ""
        sideBarServiceModel.contentMinimizedText = actionData[RDConstants.contentMinimizedText] as? String ?? ""
        sideBarServiceModel.contentMaximizedImage = actionData[RDConstants.contentMaximizedImage] as? String ?? ""
        sideBarServiceModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        sideBarServiceModel.iosLnk = actionData[RDConstants.iosLnk] as? String ?? ""
        sideBarServiceModel.staticcode = actionData[RDConstants.staticcode] as? String ?? ""

        // extended Props
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

        let report = actionData[RDConstants.report] as? [String: Any] ?? [String: Any]()
        let impression = report[RDConstants.impression] as? String ?? ""
        let click = report[RDConstants.click] as? String ?? ""
        let drawerReport = DrawerReport(impression: impression, click: click)

        sideBarServiceModel.report = drawerReport

        return sideBarServiceModel
    }
    
    
    private func parseTimerBanner(_ drawer: [String: Any?]) -> CountdownTimerBannerModel? {
        
        guard let actionData = drawer[RDConstants.actionData] as? [String: Any] else { return nil }
        var timerBannerModel = CountdownTimerBannerModel(targetingActionType: .CountdownTimerBanner)
        timerBannerModel.actId = drawer[RDConstants.actid] as? Int ?? 0
        timerBannerModel.title = drawer[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        
        
        //actionData
        timerBannerModel.scratch_color = actionData[RDConstants.scratch_color] as? String ?? ""
        timerBannerModel.ios_lnk = actionData[RDConstants.ios_lnk] as? String ?? ""
        timerBannerModel.img  = actionData[RDConstants.img] as? String ?? ""
        timerBannerModel.content_body = actionData[RDConstants.content_body] as? String ?? ""
        timerBannerModel.counter_Date = actionData[RDConstants.counter_Date] as? String ?? ""
        timerBannerModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        timerBannerModel.counter_Time = actionData[RDConstants.counter_Time] as? String ?? ""

        //extended Props
        timerBannerModel.background_color = extendedProps[RDConstants.background_color] as? String ?? ""
        timerBannerModel.counter_color = extendedProps[RDConstants.counter_color] as? String ?? ""
        timerBannerModel.close_button_color = extendedProps[RDConstants.close_button_color] as? String ?? ""
        timerBannerModel.content_body_text_color = extendedProps[RDConstants.content_body_text_color] as? String ?? ""
        timerBannerModel.position_on_page = extendedProps[RDConstants.position_on_page] as? String ?? ""
        timerBannerModel.content_body_font_family = extendedProps[RDConstants.content_body_font_family] as? String ?? ""
        timerBannerModel.txtStartDate = extendedProps[RDConstants.txtStartDate] as? String ?? ""

        
        
        let report = actionData[RDConstants.report] as? [String: Any] ?? [String: Any]()
        let impression = report[RDConstants.impression] as? String ?? ""
        let click = report[RDConstants.click] as? String ?? ""
        let drawerReport = CountdownTimerReport(impression: impression, click: click)
        
        timerBannerModel.report = drawerReport
        
        
        return timerBannerModel
    }
    
    private func parseNotificationBell(_ notificationBell: [String: Any?]) -> NotificationBellModel? {
        guard let actionData = notificationBell[RDConstants.actionData] as? [String: Any] else { return nil }
        var notificationBellModel = NotificationBellModel(targetingActionType: .notificationBell)
        notificationBellModel.actId = notificationBell[RDConstants.actid] as? Int ?? 0
        notificationBellModel.title = notificationBell[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }
        
        
        if let texts = actionData[RDConstants.notification_texts] as? [[String: Any]] {
            
            for elem in texts {
                if let text = elem[RDConstants.text] as? String,
                   let iosLink = elem[RDConstants.iosLnk] as? String {
                    
                    var ballElem = bellElement()
                    ballElem.ios_lnk = iosLink
                    ballElem.text = text
                    notificationBellModel.bellElems?.append(ballElem)

                }
            }
            
        }
        
        notificationBellModel.notifTitle = actionData[RDConstants.title] as? String ?? ""
        
        
        notificationBellModel.bellIcon = actionData[RDConstants.bell_icon] as? String ?? ""
        
        notificationBellModel.bellAnimation = actionData[RDConstants.bell_animation] as? String ?? ""
        //extended Props
        notificationBellModel.background_color = extendedProps[RDConstants.background_color] as? String ?? ""
        notificationBellModel.font_family = extendedProps[RDConstants.font_family] as? String ?? ""
        notificationBellModel.title_text_color = extendedProps[RDConstants.title_text_color] as? String ?? ""
        notificationBellModel.title_text_size = extendedProps[RDConstants.title_text_size] as? String ?? "15"
        notificationBellModel.text_text_color = extendedProps[RDConstants.text_text_color] as? String ?? ""
        notificationBellModel.text_text_size = extendedProps[RDConstants.text_text_size] as? String ?? "15"
        
        return notificationBellModel
    }

    private func parseGiftCatch(_ gamification: [String: Any?]) -> GiftCatchViewModel? {
        guard let actionData = gamification[RDConstants.actionData] as? [String: Any] else { return nil }
        var gamificationModel = GiftCatchViewModel(targetingActionType: .giftCatch)
        gamificationModel.actId = gamification[RDConstants.actid] as? Int ?? 0
        gamificationModel.title = gamification[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        gamificationModel.mailSubscription = actionData[RDConstants.mailSubscription] as? Bool ?? false
        gamificationModel.copybutton_label = actionData[RDConstants.copybuttonLabel] as? String ?? ""
        gamificationModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        gamificationModel.copybutton_function = actionData[RDConstants.copybuttonFunction] as? String ?? ""
        gamificationModel.ios_lnk = actionData[RDConstants.iosLnk] as? String ?? ""

        if let mailForm = actionData[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            gamificationModel.mailSubscriptionForm.placeholder = mailForm[RDConstants.placeholder] as? String ?? ""
            gamificationModel.mailSubscriptionForm.buttonTitle = mailForm[RDConstants.buttonLabel] as? String ?? ""
            gamificationModel.mailSubscriptionForm.consentText = mailForm[RDConstants.consentText] as? String
            gamificationModel.mailSubscriptionForm.invalidEmailMessage = mailForm[RDConstants.invalidEmailMessage] as? String ?? ""
            gamificationModel.mailSubscriptionForm.successMessage = mailForm[RDConstants.successMessage] as? String ?? ""
            gamificationModel.mailSubscriptionForm.emailPermitText = mailForm[RDConstants.emailPermitText] as? String ?? ""
            gamificationModel.mailSubscriptionForm.checkConsentMessage = mailForm[RDConstants.checkConsentMessage] as? String ?? ""
            gamificationModel.mailSubscriptionForm.title = mailForm[RDConstants.title] as? String ?? ""
            gamificationModel.mailSubscriptionForm.message = mailForm[RDConstants.message] as? String ?? ""
        }

        if let gamificationRules = actionData[RDConstants.gamificationRules] as? [String: Any] {
            gamificationModel.gamificationRules?.backgroundImage = gamificationRules[RDConstants.backgroundImage] as? String ?? ""
            gamificationModel.gamificationRules?.buttonLabel = gamificationRules[RDConstants.buttonLabel] as? String ?? ""
        }

        if let gameElements = actionData[RDConstants.gameElements] as? [String: Any] {
            gamificationModel.gameElements?.giftCatcherImage = gameElements[RDConstants.giftCatcherImage] as? String ?? ""
            gamificationModel.gameElements?.numberOfProducts = gameElements[RDConstants.numberOfProducts] as? Int ?? 0
            gamificationModel.gameElements?.downwardSpeed = gameElements[RDConstants.downwardSpeed] as? String ?? ""
            gamificationModel.gameElements?.soundUrl = gameElements[RDConstants.soundUrl] as? String ?? ""

            if let imagesString = gameElements[RDConstants.giftImages] as? [String] {
                for element in imagesString {
                    gamificationModel.gameElements?.giftImages.append(element)
                }
            }
        }

        if let gameResultElements = actionData[RDConstants.gameResultElements] as? [String: Any] {
            gamificationModel.gameResultElements?.title = gameResultElements[RDConstants.title] as? String ?? ""
            gamificationModel.gameResultElements?.message = gameResultElements[RDConstants.message] as? String ?? ""
        }

        if let promoCodes = actionData[RDConstants.promoCodes] as? [[String: Any]] {
            for promoCode in promoCodes {
                var promCode = PromoCodes()
                promCode.rangebottom = promoCode[RDConstants.rangebottom] as? Int
                promCode.rangetop = promoCode[RDConstants.rangetop] as? Int
                promCode.staticcode = promoCode[RDConstants.staticcode] as? String
                gamificationModel.promoCodes?.append(promCode)
            }
        }

        // extended props

        if let mailFormExtended = extendedProps[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            gamificationModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            gamificationModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            gamificationModel.mailExtendedProps.textColor = mailFormExtended[RDConstants.textColor] as? String ?? ""
            gamificationModel.mailExtendedProps.textSize = mailFormExtended[RDConstants.textSize] as? String ?? ""
            gamificationModel.mailExtendedProps.titleTextSize = mailFormExtended[RDConstants.titleTextSize] as? String ?? ""

            gamificationModel.mailExtendedProps.buttonColor = mailFormExtended[RDConstants.button_color] as? String ?? ""
            gamificationModel.mailExtendedProps.buttonTextColor = mailFormExtended[RDConstants.button_text_color] as? String ?? ""
            gamificationModel.mailExtendedProps.buttonTextSize = mailFormExtended[RDConstants.buttonTextSize] as? String ?? ""

            gamificationModel.mailExtendedProps.emailPermitTextSize = mailFormExtended[RDConstants.emailpermitTextSize] as? String ?? ""
            gamificationModel.mailExtendedProps.emailPermitTextUrl = mailFormExtended[RDConstants.emailpermitTextUrl] as? String ?? ""
            gamificationModel.mailExtendedProps.consentTextSize = mailFormExtended[RDConstants.consentTextSize] as? String ?? ""
            gamificationModel.mailExtendedProps.consentTextUrl = mailFormExtended[RDConstants.consentTextUrl] as? String ?? ""
            gamificationModel.mailExtendedProps.titleFontFamily = mailFormExtended[RDConstants.titleFontFamily] as? String ?? ""
        }

        gamificationModel.backgroundImage = extendedProps[RDConstants.backgroundImage] as? String ?? ""
        gamificationModel.background_color = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        gamificationModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        gamificationModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        gamificationModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        gamificationModel.promocode_background_color = extendedProps[RDConstants.promocodeBackgroundColor] as? String ?? ""
        gamificationModel.promocode_text_color = extendedProps[RDConstants.promocodeTextColor] as? String ?? ""
        gamificationModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        gamificationModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        gamificationModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        gamificationModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        gamificationModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        gamificationModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        gamificationModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        gamificationModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""

        if let gameficationRuleExtended = extendedProps[RDConstants.gamificationRules] as? [String: Any] {
            gamificationModel.gamificationRulesExtended?.buttonColor = gameficationRuleExtended[RDConstants.button_color] as? String ?? ""
            gamificationModel.gamificationRulesExtended?.buttonTextColor = gameficationRuleExtended[RDConstants.button_text_color] as? String ?? ""
            gamificationModel.gamificationRulesExtended?.buttonTextSize = gameficationRuleExtended[RDConstants.buttonTextSize] as? String ?? ""
        }

        if let gameficationElementExtended = extendedProps[RDConstants.gameElements] as? [String: Any] {
            gamificationModel.gameElementsExtended?.scoreboardShape = gameficationElementExtended[RDConstants.scoreboardShape] as? String ?? ""
            gamificationModel.gameElementsExtended?.scoreboardBackgroundColor = gameficationElementExtended[RDConstants.scoreboardBackgroundColor] as? String ?? ""
        }

        if let gameficationResultElementExtended = extendedProps[RDConstants.gameResultElements] as? [String: Any] {
            gamificationModel.gameResultElementsExtended?.titleTextColor = gameficationResultElementExtended[RDConstants.titleTextColor] as? String ?? ""
            gamificationModel.gameResultElementsExtended?.titleTextSize = gameficationResultElementExtended[RDConstants.titleTextSize] as? String ?? ""
            gamificationModel.gameResultElementsExtended?.textColor = gameficationResultElementExtended[RDConstants.textColor] as? String ?? ""
            gamificationModel.gameResultElementsExtended?.textColor = gameficationResultElementExtended[RDConstants.textColor] as? String ?? ""

            gamificationModel.gameResultElementsExtended?.textSize = extendedProps[RDConstants.textSize] as? String ?? ""
        }

        if gamificationModel.promocode_banner_button_label.count > 0 && gamificationModel.promocode_banner_text.count > 0 {
            gamificationModel.bannercodeShouldShow = true
        } else {
            gamificationModel.bannercodeShouldShow = false
        }

        return gamificationModel
    }

    private func parseFindToWin(_ findToWin: [String: Any?]) -> FindToWinViewModel? {
        guard let actionData = findToWin[RDConstants.actionData] as? [String: Any] else { return nil }
        var findToWinModel = FindToWinViewModel(targetingActionType: .findToWin)
        findToWinModel.actId = findToWin[RDConstants.actid] as? Int ?? 0
        findToWinModel.title = findToWin[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        findToWinModel.mailSubscription = actionData[RDConstants.mailSubscription] as? Bool ?? false
        findToWinModel.copybutton_label = actionData[RDConstants.copybuttonLabel] as? String ?? ""
        findToWinModel.copybutton_function = actionData[RDConstants.copybuttonFunction] as? String ?? ""
        findToWinModel.ios_lnk = actionData[RDConstants.iosLnk] as? String ?? ""
        findToWinModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let mailForm = actionData[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            findToWinModel.mailSubscriptionForm.placeholder = mailForm[RDConstants.placeholder] as? String ?? ""
            findToWinModel.mailSubscriptionForm.buttonTitle = mailForm[RDConstants.buttonLabel] as? String ?? ""
            findToWinModel.mailSubscriptionForm.consentText = mailForm[RDConstants.consentText] as? String
            findToWinModel.mailSubscriptionForm.invalidEmailMessage = mailForm[RDConstants.invalidEmailMessage] as? String ?? ""
            findToWinModel.mailSubscriptionForm.successMessage = mailForm[RDConstants.successMessage] as? String ?? ""
            findToWinModel.mailSubscriptionForm.emailPermitText = mailForm[RDConstants.emailPermitText] as? String ?? ""
            findToWinModel.mailSubscriptionForm.checkConsentMessage = mailForm[RDConstants.checkConsentMessage] as? String ?? ""
            findToWinModel.mailSubscriptionForm.title = mailForm[RDConstants.title] as? String ?? ""
            findToWinModel.mailSubscriptionForm.message = mailForm[RDConstants.message] as? String ?? ""
        }

        if let gamificationRules = actionData[RDConstants.gamificationRules] as? [String: Any] {
            findToWinModel.gamificationRules?.backgroundImage = gamificationRules[RDConstants.backgroundImage] as? String ?? ""
            findToWinModel.gamificationRules?.buttonLabel = gamificationRules[RDConstants.buttonLabel] as? String ?? ""
        }

        if let gameElements = actionData[RDConstants.gameElements] as? [String: Any] {
            findToWinModel.gameElements?.playgroundRowcount = gameElements[RDConstants.playgroundRowcount] as? Int ?? 0
            findToWinModel.gameElements?.playgroundColumncount = gameElements[RDConstants.playgroundColumncount] as? Int ?? 0
            findToWinModel.gameElements?.durationOfGame = gameElements[RDConstants.durationOfGame] as? Int ?? 0
            findToWinModel.gameElements?.soundUrl = gameElements[RDConstants.soundUrl] as? String ?? ""

            if let imagesString = gameElements[RDConstants.cardImages] as? [String] {
                for element in imagesString {
                    findToWinModel.gameElements?.cardImages.append(element)
                }
            }
        }

        if let gameResultElements = actionData[RDConstants.gameResultElements] as? [String: Any] {
            findToWinModel.gameResultElements?.title = gameResultElements[RDConstants.title] as? String ?? ""
            findToWinModel.gameResultElements?.message = gameResultElements[RDConstants.message] as? String ?? ""
            findToWinModel.gameResultElements?.loseImage = gameResultElements[RDConstants.loseImage] as? String ?? ""
            findToWinModel.gameResultElements?.loseButtonLabel = gameResultElements[RDConstants.loseButtonLabel] as? String ?? ""
            findToWinModel.gameResultElements?.loseIosLnk = gameResultElements[RDConstants.loseIosLnk] as? String ?? ""
        }

        if let promoCodes = actionData[RDConstants.promoCodes] as? [[String: Any]] {
            for promoCode in promoCodes {
                var promCode = PromoCodes()
                promCode.rangebottom = promoCode[RDConstants.rangebottom] as? Int
                promCode.rangetop = promoCode[RDConstants.rangetop] as? Int
                promCode.staticcode = promoCode[RDConstants.staticcode] as? String
                findToWinModel.promoCodes?.append(promCode)
            }
        }

        // extended props

        if let mailFormExtended = extendedProps[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            findToWinModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            findToWinModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            findToWinModel.mailExtendedProps.textColor = mailFormExtended[RDConstants.textColor] as? String ?? ""
            findToWinModel.mailExtendedProps.textSize = mailFormExtended[RDConstants.textSize] as? String ?? ""
            findToWinModel.mailExtendedProps.titleTextSize = mailFormExtended[RDConstants.titleTextSize] as? String ?? ""
            findToWinModel.mailExtendedProps.buttonColor = mailFormExtended[RDConstants.button_color] as? String ?? ""
            findToWinModel.mailExtendedProps.buttonTextColor = mailFormExtended[RDConstants.button_text_color] as? String ?? ""
            findToWinModel.mailExtendedProps.buttonTextSize = mailFormExtended[RDConstants.buttonTextSize] as? String ?? ""

            findToWinModel.mailExtendedProps.emailPermitTextSize = mailFormExtended[RDConstants.emailpermitTextSize] as? String ?? ""
            findToWinModel.mailExtendedProps.emailPermitTextUrl = mailFormExtended[RDConstants.emailpermitTextUrl] as? String ?? ""
            findToWinModel.mailExtendedProps.consentTextSize = mailFormExtended[RDConstants.consentTextSize] as? String ?? ""
            findToWinModel.mailExtendedProps.consentTextUrl = mailFormExtended[RDConstants.consentTextUrl] as? String ?? ""
            findToWinModel.mailExtendedProps.titleFontFamily = mailFormExtended[RDConstants.titleFontFamily] as? String ?? ""
        }

        findToWinModel.backgroundImage = extendedProps[RDConstants.backgroundImage] as? String ?? ""
        findToWinModel.background_color = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        findToWinModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        findToWinModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        findToWinModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        findToWinModel.promocode_background_color = extendedProps[RDConstants.promocodeBackgroundColor] as? String ?? ""
        findToWinModel.promocode_text_color = extendedProps[RDConstants.promocodeTextColor] as? String ?? ""
        findToWinModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        findToWinModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        findToWinModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        findToWinModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        findToWinModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        findToWinModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        findToWinModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        findToWinModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""

        if let gameficationRuleExtended = extendedProps[RDConstants.gamificationRules] as? [String: Any] {
            findToWinModel.gamificationRulesExtended?.buttonColor = gameficationRuleExtended[RDConstants.button_color] as? String ?? ""
            findToWinModel.gamificationRulesExtended?.buttonTextColor = gameficationRuleExtended[RDConstants.button_text_color] as? String ?? ""
            findToWinModel.gamificationRulesExtended?.buttonTextSize = gameficationRuleExtended[RDConstants.buttonTextSize] as? String ?? ""
        }

        if let gameficationElementExtended = extendedProps[RDConstants.gameElements] as? [String: Any] {
            findToWinModel.gameElementsExtended?.scoreboardShape = gameficationElementExtended[RDConstants.scoreboardShape] as? String ?? ""
            findToWinModel.gameElementsExtended?.scoreboardBackgroundColor = gameficationElementExtended[RDConstants.scoreboardBackgroundColor] as? String ?? ""

            findToWinModel.gameElementsExtended?.scoreboardPageposition = gameficationElementExtended[RDConstants.scoreboardPageposition] as? String ?? ""
            findToWinModel.gameElementsExtended?.backofcardsImage = gameficationElementExtended[RDConstants.backofcardsImage] as? String ?? ""
            findToWinModel.gameElementsExtended?.backofcardsColor = gameficationElementExtended[RDConstants.backofcardsColor] as? String ?? ""
            findToWinModel.gameElementsExtended?.blankcardImage = gameficationElementExtended[RDConstants.blankcardImage] as? String ?? ""
        }

        if let gameficationResultElementExtended = extendedProps[RDConstants.gameResultElements] as? [String: Any] {
            findToWinModel.gameResultElementsExtended?.titleTextColor = gameficationResultElementExtended[RDConstants.titleTextColor] as? String ?? ""
            findToWinModel.gameResultElementsExtended?.titleTextSize = gameficationResultElementExtended[RDConstants.titleTextSize] as? String ?? ""
            findToWinModel.gameResultElementsExtended?.textColor = gameficationResultElementExtended[RDConstants.textColor] as? String ?? ""
            findToWinModel.gameResultElementsExtended?.textSize = extendedProps[RDConstants.textSize] as? String ?? ""

            findToWinModel.gameResultElementsExtended?.losebuttonColor = gameficationResultElementExtended[RDConstants.losebuttonColor] as? String ?? ""
            findToWinModel.gameResultElementsExtended?.losebuttonTextColor = gameficationResultElementExtended[RDConstants.losebuttonTextColor] as? String ?? ""
            findToWinModel.gameResultElementsExtended?.losebuttonTextSize = extendedProps[RDConstants.losebuttonTextSize] as? String ?? ""
        }

        if findToWinModel.promocode_banner_button_label.count > 0 && findToWinModel.promocode_banner_text.count > 0 {
            findToWinModel.bannercodeShouldShow = true
        } else {
            findToWinModel.bannercodeShouldShow = false
        }

        return findToWinModel
    }

    private func parseChooseFavorite(_ chooseFavorite: [String: Any?]) -> ChooseFavoriteModel? {
        guard let actionData = chooseFavorite[RDConstants.actionData] as? [String: Any] else { return nil }
        var chooseFavoriteModel = ChooseFavoriteModel(targetingActionType: .chooseFavorite)
        chooseFavoriteModel.actId = chooseFavorite[RDConstants.actid] as? Int ?? 0
        chooseFavoriteModel.title = chooseFavorite[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        // prome banner params
        chooseFavoriteModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        chooseFavoriteModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        chooseFavoriteModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        chooseFavoriteModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        chooseFavoriteModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        chooseFavoriteModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        chooseFavoriteModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        chooseFavoriteModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        chooseFavoriteModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        chooseFavoriteModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        //
        chooseFavoriteModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: chooseFavorite,
            options: []) {
            chooseFavoriteModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if chooseFavoriteModel.promocode_banner_button_label.count > 0 && chooseFavoriteModel.promocode_banner_text.count > 0 {
            chooseFavoriteModel.bannercodeShouldShow = true
        } else {
            chooseFavoriteModel.bannercodeShouldShow = false
        }

        return chooseFavoriteModel
    }
    
    
    private func parseInappRating(_ inappratingModel: [String: Any?]) -> InappReviewModel? {
        guard let actionData = inappratingModel[RDConstants.actionData] as? [String: Any] else { return nil }
        var inappRating = InappReviewModel(targetingActionType: .apprating)
        inappRating.actId = inappratingModel[RDConstants.actid] as? Int ?? 0
        inappRating.title = inappratingModel[RDConstants.title] as? String ?? ""

        return inappRating
    }
    
    private func parseCustomWebview(_ customWebView: [String: Any?]) -> CustomWebViewModel? {
        guard let actionData = customWebView[RDConstants.actionData] as? [String: Any] else { return nil }
        var customWebviewModel = CustomWebViewModel(targetingActionType: .mobileCustomActions)
        customWebviewModel.actId = customWebView[RDConstants.actid] as? Int ?? 0
        customWebviewModel.title = customWebView[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        customWebviewModel.htmlContent = actionData[RDConstants.content] as? String ?? ""
        customWebviewModel.jsContent = actionData[RDConstants.javascript] as? String ?? ""

         //prome banner params
        customWebviewModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        customWebviewModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        customWebviewModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        customWebviewModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        customWebviewModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        customWebviewModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        customWebviewModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        customWebviewModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        customWebviewModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        customWebviewModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        //

        customWebviewModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0
        customWebviewModel.position = extendedProps[RDConstants.positionCustom] as? String ?? ""
        customWebviewModel.width = extendedProps[RDConstants.width] as? Float ?? 0.0
        customWebviewModel.height = extendedProps[RDConstants.height] as? Float ?? 0.0
        customWebviewModel.closeButtonColor = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        customWebviewModel.borderRadius = extendedProps[RDConstants.borderRadius] as? Float ?? 0.0
        
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: customWebView,
            options: []) {
            customWebviewModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if customWebviewModel.promocode_banner_button_label.count > 0 && customWebviewModel.promocode_banner_text.count > 0 {
            customWebviewModel.bannercodeShouldShow = true
        } else {
            customWebviewModel.bannercodeShouldShow = false
        }

        return customWebviewModel
    }

    private func parseJackpot(_ jackpot: [String: Any?]) -> JackpotModel? {
        guard let actionData = jackpot[RDConstants.actionData] as? [String: Any] else { return nil }
        var jackpotModel = JackpotModel(targetingActionType: .slotMachine)
        jackpotModel.actId = jackpot[RDConstants.actid] as? Int ?? 0
        jackpotModel.title = jackpot[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        // prome banner params
        jackpotModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        jackpotModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        jackpotModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        jackpotModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        jackpotModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        jackpotModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        jackpotModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        jackpotModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        jackpotModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        jackpotModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        //
        jackpotModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: jackpot,
            options: []) {
            jackpotModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if jackpotModel.promocode_banner_button_label.count > 0 && jackpotModel.promocode_banner_text.count > 0 {
            jackpotModel.bannercodeShouldShow = true
        } else {
            jackpotModel.bannercodeShouldShow = false
        }

        return jackpotModel
    }
    
    
    private func parsePoll(_ poll: [String: Any?]) -> PollModel? {
        guard let actionData = poll[RDConstants.actionData] as? [String: Any] else { return nil }
        var pollModel = PollModel(targetingActionType: .MultipleChoiceSurvey)
        pollModel.actId = poll[RDConstants.actid] as? Int ?? 0
        pollModel.title = poll[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        // prome banner params
        pollModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        pollModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        pollModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        pollModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        pollModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        pollModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        pollModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        pollModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        pollModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        pollModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        //
        pollModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: poll,
            options: []) {
            pollModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if pollModel.promocode_banner_button_label.count > 0 && pollModel.promocode_banner_text.count > 0 {
            pollModel.bannercodeShouldShow = true
        } else {
            pollModel.bannercodeShouldShow = false
        }

        return pollModel
    }
    
    
    private func parseClawMachine(_ clowMachine: [String: Any?]) -> ClawMachineModel? {
        
        guard let actionData = clowMachine[RDConstants.actionData] as? [String: Any] else { return nil }
        var ClowMachineModel = ClawMachineModel(targetingActionType: .clawMachine)
        ClowMachineModel.actId = clowMachine[RDConstants.actid] as? Int ?? 0
        ClowMachineModel.title = clowMachine[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        // prome banner params
        ClowMachineModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        ClowMachineModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        ClowMachineModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        ClowMachineModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        ClowMachineModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        ClowMachineModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        ClowMachineModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        ClowMachineModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        ClowMachineModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        ClowMachineModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        //
        ClowMachineModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: clowMachine,
            options: []) {
            ClowMachineModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if ClowMachineModel.promocode_banner_button_label.count > 0 && ClowMachineModel.promocode_banner_text.count > 0 {
            ClowMachineModel.bannercodeShouldShow = true
        } else {
            ClowMachineModel.bannercodeShouldShow = false
        }

        return ClowMachineModel
    }


    private func parseGiftBox(_ giftBox: [String: Any?]) -> GiftBoxModel? {
        guard let actionData = giftBox[RDConstants.actionData] as? [String: Any] else { return nil }
        var giftBoxModel = GiftBoxModel(targetingActionType: .giftBox)
        giftBoxModel.actId = giftBox[RDConstants.actid] as? Int ?? 0
        giftBoxModel.title = giftBox[RDConstants.title] as? String ?? ""
        let encodedStr = actionData[RDConstants.extendedProps] as? String ?? ""
        guard let extendedProps = encodedStr.urlDecode().convertJsonStringToDictionary() else { return nil }

        giftBoxModel.mailSubscription = actionData[RDConstants.mailSubscription] as? Bool ?? false
        giftBoxModel.copybutton_label = actionData[RDConstants.copybuttonLabel] as? String ?? ""
        giftBoxModel.copybutton_function = actionData[RDConstants.copybuttonFunction] as? String ?? ""
        giftBoxModel.ios_lnk = actionData[RDConstants.iosLnk] as? String ?? ""
        giftBoxModel.waitingTime = actionData[RDConstants.waitingTime] as? Int ?? 0

        if let mailForm = actionData[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            giftBoxModel.mailSubscriptionForm.placeholder = mailForm[RDConstants.placeholder] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.buttonTitle = mailForm[RDConstants.buttonLabel] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.consentText = mailForm[RDConstants.consentText] as? String
            giftBoxModel.mailSubscriptionForm.invalidEmailMessage = mailForm[RDConstants.invalidEmailMessage] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.successMessage = mailForm[RDConstants.successMessage] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.emailPermitText = mailForm[RDConstants.emailPermitText] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.checkConsentMessage = mailForm[RDConstants.checkConsentMessage] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.title = mailForm[RDConstants.title] as? String ?? ""
            giftBoxModel.mailSubscriptionForm.message = mailForm[RDConstants.message] as? String ?? ""
        }

        if let gamificationRules = actionData[RDConstants.gamificationRules] as? [String: Any] {
            giftBoxModel.gamificationRules?.backgroundImage = gamificationRules[RDConstants.backgroundImage] as? String ?? ""
            giftBoxModel.gamificationRules?.buttonLabel = gamificationRules[RDConstants.buttonLabel] as? String ?? ""
        }

        if let gameElements = actionData[RDConstants.gameElements] as? [String: Any] {
            if let gameDetailElement = gameElements[RDConstants.giftBoxes] as? [[String: Any]] {
                for element in gameDetailElement {
                    var giftBoxElem = GiftBox()
                    giftBoxElem.image = element[RDConstants.image] as? String ?? ""
                    giftBoxElem.staticcode = element[RDConstants.staticcode] as? String ?? ""

                    giftBoxModel.gameElements?.append(giftBoxElem)
                }
            }
        }

        if let gameResultElements = actionData[RDConstants.gameResultElements] as? [String: Any] {
            giftBoxModel.gameResultElements?.image = gameResultElements[RDConstants.image] as? String ?? ""
            giftBoxModel.gameResultElements?.title = gameResultElements[RDConstants.title] as? String ?? ""
            giftBoxModel.gameResultElements?.message = gameResultElements[RDConstants.message] as? String ?? ""
        }

        if let promoCodes = actionData[RDConstants.promoCodes] as? [[String: Any]] {
            for promoCode in promoCodes {
                var promCode = PromoCodes()
                promCode.rangebottom = promoCode[RDConstants.rangebottom] as? Int
                promCode.rangetop = promoCode[RDConstants.rangetop] as? Int
                promCode.staticcode = promoCode[RDConstants.staticcode] as? String
                giftBoxModel.promoCodes?.append(promCode)
            }
        }

        // extended props

        if let mailFormExtended = extendedProps[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            giftBoxModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            giftBoxModel.mailExtendedProps.titleTextColor = mailFormExtended[RDConstants.titleTextColor] as? String ?? ""
            giftBoxModel.mailExtendedProps.textColor = mailFormExtended[RDConstants.textColor] as? String ?? ""
            giftBoxModel.mailExtendedProps.textSize = mailFormExtended[RDConstants.textSize] as? String ?? ""
            giftBoxModel.mailExtendedProps.titleTextSize = mailFormExtended[RDConstants.titleTextSize] as? String ?? ""
            giftBoxModel.mailExtendedProps.buttonColor = mailFormExtended[RDConstants.button_color] as? String ?? ""
            giftBoxModel.mailExtendedProps.buttonTextColor = mailFormExtended[RDConstants.button_text_color] as? String ?? ""
            giftBoxModel.mailExtendedProps.buttonTextSize = mailFormExtended[RDConstants.buttonTextSize] as? String ?? ""

            giftBoxModel.mailExtendedProps.emailPermitTextSize = mailFormExtended[RDConstants.emailpermitTextSize] as? String ?? ""
            giftBoxModel.mailExtendedProps.emailPermitTextUrl = mailFormExtended[RDConstants.emailpermitTextUrl] as? String ?? ""
            giftBoxModel.mailExtendedProps.consentTextSize = mailFormExtended[RDConstants.consentTextSize] as? String ?? ""
            giftBoxModel.mailExtendedProps.consentTextUrl = mailFormExtended[RDConstants.consentTextUrl] as? String ?? ""
            giftBoxModel.mailExtendedProps.titleFontFamily = mailFormExtended[RDConstants.titleFontFamily] as? String ?? ""
        }

        giftBoxModel.backgroundImage = extendedProps[RDConstants.backgroundImage] as? String ?? ""
        giftBoxModel.background_color = extendedProps[RDConstants.backgroundColor] as? String ?? ""
        giftBoxModel.font_family = extendedProps[RDConstants.fontFamily] as? String ?? ""
        giftBoxModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""
        giftBoxModel.close_button_color = extendedProps[RDConstants.closeButtonColor] as? String ?? ""
        giftBoxModel.promocode_background_color = extendedProps[RDConstants.promocodeBackgroundColor] as? String ?? ""
        giftBoxModel.promocode_text_color = extendedProps[RDConstants.promocodeTextColor] as? String ?? ""
        giftBoxModel.copybutton_color = extendedProps[RDConstants.copybuttonColor] as? String ?? ""
        giftBoxModel.copybutton_text_color = extendedProps[RDConstants.copybuttonTextColor] as? String ?? ""
        giftBoxModel.copybutton_text_size = extendedProps[RDConstants.copybuttonTextSize] as? String ?? ""
        giftBoxModel.promocode_banner_text = extendedProps[RDConstants.promocode_banner_text] as? String ?? ""
        giftBoxModel.promocode_banner_text_color = extendedProps[RDConstants.promocode_banner_text_color] as? String ?? ""
        giftBoxModel.promocode_banner_background_color = extendedProps[RDConstants.promocode_banner_background_color] as? String ?? ""
        giftBoxModel.promocode_banner_button_label = extendedProps[RDConstants.promocode_banner_button_label] as? String ?? ""
        giftBoxModel.custom_font_family_ios = extendedProps[RDConstants.customFontFamilyIos] as? String ?? ""

        if let gameficationRuleExtended = extendedProps[RDConstants.gamificationRules] as? [String: Any] {
            giftBoxModel.gamificationRulesExtended?.buttonColor = gameficationRuleExtended[RDConstants.button_color] as? String ?? ""
            giftBoxModel.gamificationRulesExtended?.buttonTextColor = gameficationRuleExtended[RDConstants.button_text_color] as? String ?? ""
            giftBoxModel.gamificationRulesExtended?.buttonTextSize = gameficationRuleExtended[RDConstants.buttonTextSize] as? String ?? ""
        }

        if let gameficationResultElementExtended = extendedProps[RDConstants.gameResultElements] as? [String: Any] {
            giftBoxModel.gameResultElementsExtended?.titleTextColor = gameficationResultElementExtended[RDConstants.titleTextColor] as? String ?? ""
            giftBoxModel.gameResultElementsExtended?.titleTextSize = gameficationResultElementExtended[RDConstants.titleTextSize] as? String ?? ""
            giftBoxModel.gameResultElementsExtended?.textColor = gameficationResultElementExtended[RDConstants.textColor] as? String ?? ""
            giftBoxModel.gameResultElementsExtended?.textSize = extendedProps[RDConstants.textSize] as? String ?? ""
        }

        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: giftBox,
            options: []) {
            giftBoxModel.jsonContent = String(data: theJSONData, encoding: .utf8)
        }

        if giftBoxModel.promocode_banner_button_label.count > 0 && giftBoxModel.promocode_banner_text.count > 0 {
            giftBoxModel.bannercodeShouldShow = true
        } else {
            giftBoxModel.bannercodeShouldShow = false
        }

        return giftBoxModel
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

        if let mailForm = actionData[RDConstants.gMailSubscriptionForm] as? [String: Any] {
            mailPlaceholder = mailForm[RDConstants.placeholder] as? String
            mailButtonTxt = mailForm[RDConstants.buttonLabel] as? String
            consentText = mailForm[RDConstants.consentText] as? String
            invalidEmailMsg = mailForm[RDConstants.invalidEmailMessage] as? String
            successMsg = mailForm[RDConstants.successMessage] as? String
            emailPermitTxt = mailForm[RDConstants.emailPermitText] as? String
            checkConsentMsg = mailForm[RDConstants.checkConsentMessage] as? String
        }

        let iosLink = actionData[RDConstants.iosLnk] as? String ?? ""

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
                                 contentTitleCustomFontFamilyIos: contentTitleCustomFontFamilyIos,
                                 contentBodyCustomFontFamilyIos: contentBodyCustomFontFamilyIos,
                                 buttonCustomFontFamilyIos: buttonCustomFontFamilyIos,
                                 promocodeCustomFontFamilyIos: promocodeCustomFontFamilyIos,
                                 copybuttonCustomFontFamilyIos: copybuttonCustomFontFamilyIos,
                                 iosLink: iosLink)
    }

    private func convertJsonToEmailViewModel(emailForm: MailSubscriptionModel) -> MailSubscriptionViewModel {
        var parsedConsent: ParsedPermissionString?
        if let consent = emailForm.consentText, !consent.isEmpty {
            parsedConsent = consent.parsePermissionText()
        }
        let parsedPermit = emailForm.emailPermitText.parsePermissionText()
        let titleFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.titleFontFamily,
                                         fontSize: emailForm.extendedProps.titleTextSize,
                                         style: .title2, customFont: emailForm.extendedProps.titleCustomFontFamilyIos)
        let messageFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.textFontFamily,
                                           fontSize: emailForm.extendedProps.textSize,
                                           style: .body, customFont: emailForm.extendedProps.textCustomFontFamilyIos)
        let buttonFont = RDHelper.getFont(fontFamily: emailForm.extendedProps.buttonFontFamily,
                                          fontSize: emailForm.extendedProps.buttonTextSize,
                                          style: .title2, customFont: emailForm.extendedProps.buttonCustomFontFamilyIos)
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
        props[RDConstants.organizationIdKey] = rdProfile.organizationId
        props[RDConstants.profileIdKey] = rdProfile.profileId
        props[RDConstants.cookieIdKey] = rdUser.cookieId
        props[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RDConstants.tokenIdKey] = rdUser.tokenId
        props[RDConstants.appidKey] = rdUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        props[RDConstants.utmCampaignKey] = rdUser.utmCampaign
        props[RDConstants.utmContentKey] = rdUser.utmContent
        props[RDConstants.utmMediumKey] = rdUser.utmMedium
        props[RDConstants.utmSourceKey] = rdUser.utmSource
        props[RDConstants.utmTermKey] = rdUser.utmTerm
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

    func getAppBanner(properties: Properties, rdUser: RDUser, guid: String, completion: @escaping ((_ response: AppBannerResponseModel) -> Void)) {
        RDRequest.sendMobileRequest(properties: properties, headers: Properties(), completion: { (result: [String: Any]?, error: RDError?, guid: String?) in
            completion(self.parseBannerApp(result, error, guid))
        }, guid: guid)
    }

    private func parseBannerApp(_ result: [String: Any]?, _ error: RDError?, _ guid: String?) -> AppBannerResponseModel {
        var appBannerModelArray = [AppBannerModel]()
        var errorResponse: RDError?
        var transition: String?
        if let error = error {
            errorResponse = error
        } else if let res = result {
            if let bannerAction = res[RDConstants.appBanner] as? [[String: Any?]] {
                for bannerAction in bannerAction {
                    let actiondata = bannerAction[RDConstants.actionData] as? [String: Any?]
                    let appData = actiondata?[RDConstants.appBanners] as? [[String: Any?]]
                    transition = actiondata?[RDConstants.transitionAction] as? String
                    for element in appData! {
                        let appBannerModel = AppBannerModel(img: element[RDConstants.img] as? String, ios_lnk: element[RDConstants.iosLnk] as? String)
                        appBannerModelArray.append(appBannerModel)
                    }
                }
            } else {
                errorResponse = RDError.noData
            }
        }

        if appBannerModelArray.isEmpty {
            errorResponse = RDError.noData
        }

        return AppBannerResponseModel(app_banners: appBannerModelArray, error: errorResponse, transition: transition ?? "")
    }

    func getButtonCarouselView(properties: Properties, rdUser: RDUser, guid: String, completion: @escaping ((_ response: ButtonCarouselViewModel) -> Void)) {
        RDRequest.sendMobileRequest(properties: properties, headers: Properties(), completion: { (result: [String: Any]?, error: RDError?, guid: String?) in
            completion(self.parseButtonCarouselView(result, error, guid))
        }, guid: guid)
    }

    private func parseButtonCarouselView(_ result: [String: Any]?, _ error: RDError?, _ guid: String?) -> ButtonCarouselViewModel {
        var appBannerModelArray = [AppBannerModel]()
        var errorResponse: RDError?
        var transition: String?
        if let error = error {
            errorResponse = error
        } else if let res = result {
            if let bannerAction = res[RDConstants.appBanner] as? [[String: Any?]] {
                for bannerAction in bannerAction {
                    let actiondata = bannerAction[RDConstants.actionData] as? [String: Any?]
                    let appData = actiondata?[RDConstants.appBanners] as? [[String: Any?]]
                    transition = actiondata?[RDConstants.transitionAction] as? String
                    for element in appData! {
                        let appBannerModel = AppBannerModel(img: element[RDConstants.img] as? String, ios_lnk: element[RDConstants.iosLnk] as? String)
                        appBannerModelArray.append(appBannerModel)
                    }
                }
            } else {
                errorResponse = RDError.noData
            }
        }

        if appBannerModelArray.isEmpty {
            errorResponse = RDError.noData
        }

        return ButtonCarouselViewModel()
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
        props[RDConstants.utmCampaignKey] = rdUser.utmCampaign
        props[RDConstants.utmContentKey] = rdUser.utmContent
        props[RDConstants.utmMediumKey] = rdUser.utmMedium
        props[RDConstants.utmSourceKey] = rdUser.utmSource
        props[RDConstants.utmTermKey] = rdUser.utmTerm
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

        RDRequest.sendMobileRequest(properties: props, headers: Properties(), completion: { (result: [String: Any]?, error: RDError?, guid: String?) in
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
                       let template = RDStoryTemplate(rawValue: templateString) {
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
        let targetUrl = (item[RDConstants.targetUrl] as? String) ?? ""
        let buttonText = (item[RDConstants.buttonText] as? String) ?? ""
        var displayTime = 3
        if let dTime = item[RDConstants.displayTime] as? Int, dTime > 0 {
            displayTime = dTime
        }
        var buttonTextColor = UIColor.white
        var buttonColor = UIColor.black
        if let buttonTextColorString = item[RDConstants.buttonTextColor] as? String {
            if buttonTextColorString.starts(with: "rgba") {
                if let btColor = UIColor(rgbaString: buttonTextColorString) {
                    buttonTextColor = btColor
                }
            } else {
                if let btColor = UIColor(hex: buttonTextColorString) {
                    buttonTextColor = btColor
                }
            }
        }
        if let buttonColorString = item[RDConstants.buttonColor] as? String {
            if buttonColorString.starts(with: "rgba") {
                if let bColor = UIColor(rgbaString: buttonColorString) {
                    buttonColor = bColor
                }
            } else {
                if let bColor = UIColor(hex: buttonColorString) {
                    buttonColor = bColor
                }
            }
        }

        var countDownModel = RDStoryCountDown()
        if let countDown = item[RDConstants.countDown] as? [String: String] {
            countDownModel.pagePosition = countDown[RDConstants.pagePosition]
            countDownModel.messageText = countDown[RDConstants.messageText]
            countDownModel.messageTextSize = countDown[RDConstants.messageTextSize]
            countDownModel.messageTextColor = countDown[RDConstants.messageTextColor]
            countDownModel.displayType = countDown[RDConstants.displayType]
            countDownModel.endDateTime = countDown[RDConstants.endDateTime]
            countDownModel.endAction = countDown[RDConstants.endAction]
            countDownModel.endAnimationImageUrl = countDown[RDConstants.endAnimationImageUrl]
            countDownModel.gifImage = UIImage.gif(url: countDownModel.endAnimationImageUrl ?? "")
        }

        let relatedDigitalStoryItem = RDStoryItem(fileType: fileType,
                                                  displayTime: displayTime,
                                                  fileSrc: fileSrc,
                                                  targetUrl: targetUrl,
                                                  buttonText: buttonText,
                                                  buttonTextColor: buttonTextColor,
                                                  buttonColor: buttonColor,
                                                  countDown: countDownModel)
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
                    if let imageBorderColor = UIColor(rgbaString: imageBorderColorString) {
                        props.imageBorderColor = imageBorderColor
                    }
                } else {
                    if let imageBorderColor = UIColor(hex: imageBorderColorString) {
                        props.imageBorderColor = imageBorderColor
                    }
                }
            }
            if let labelColorString = extendedProps[RDConstants.storylbLabelColor] as? String {
                if labelColorString.starts(with: "rgba") {
                    if let labelColor = UIColor(rgbaString: labelColorString) {
                        props.labelColor = labelColor
                    }
                } else {
                    if let labelColor = UIColor(hex: labelColorString) {
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

    // MARK: - NPS With Numbers

    func getNpsWithNumbers(properties: Properties, rdUser: RDUser, guid: String, completion: @escaping ((_ response: RDInAppNotification?) -> Void)) {
        RDRequest.sendInAppNotificationRequest(properties: properties, headers: Properties(), completion: { rdInAppNotificationResult in
            guard let result = rdInAppNotificationResult else {
                completion(nil)
                return
            }
            var notif: RDInAppNotification?

            for rawNotif in result {
                if let actionData = rawNotif["actiondata"] as? [String: Any] {
                    if let typeString = actionData["msg_type"] as? String,
                       RDInAppNotificationType(rawValue: typeString) != nil,
                       let notification = RDInAppNotification(JSONObject: rawNotif), notification.displayType == RDConstants.inline {
                        notif = notification
                    }
                }
            }
            completion(notif)
        })
    }
}
