//
//  PlinkoViewController.swift
//  RelatedDigitalIOS
//
//  Plinko oyununu gösteren WebView controller'ı. JS içeriği sunucudan
//  (mbls.visilabs.net/plinko.js) indirilir, HTML ise SDK içinde paketlidir.
//

import UIKit
import WebKit

class PlinkoViewController: RDBaseNotificationViewController {

    weak var webView: WKWebView!
    var subsEmail = ""
    var sliceText = ""
    var sliceLink: String?
    var codeGotten = false

    var pIndexCodes = [Int: String]()
    var pIndexDisplayNames = [Int: String]()
    var sIndexCodes = [Int: String]()
    var sIndexDisplayNames = [Int: String]()
    var sliceLinks = [Int: String]()

    init(_ model: PlinkoModel) {
        super.init(nibName: nil, bundle: nil)
        self.plinko = model
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = configureWebView()
        self.view.addSubview(webView)
        webView.allEdges(to: self.view)
    }

    func configureWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "eventHandler")
        configuration.userContentController = userContentController
        configuration.preferences.javaScriptEnabled = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if let htmlUrl = createPlinkoFiles() {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.translatesAutoresizingMaskIntoConstraints = false
        }
        return webView
    }

    private func close() {
        self.dismiss(animated: true) {

            if let sliceLink = self.sliceLink,
               !sliceLink.isEmptyOrWhitespace,
               let url = URL(string: sliceLink),
               self.plinko?.copyButtonFunction == RDConstants.copyRedirect {
                DispatchQueue.main.async {
                    let app = RDInstance.sharedUIApplication()
                    app?.performSelector(onMainThread: NSSelectorFromString("openURL:"), with: url, waitUntilDone: true)
                }
            }

            if let plinko = self.plinko, plinko.bannercodeShouldShow ?? false, self.codeGotten {
                let bannerVC = RDPlinkoCodeBannerController(plinko)
                bannerVC.delegate = self.delegate
                bannerVC.show(animated: true)
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            } else {
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            }
        }
    }

    private func sendPromotionCodeInfo(promo: String, actId: String, email: String? = "", promoTitle: String, promoSlice: String) {
        var properties = Properties()
        properties[RDConstants.promoAction] = promo
        properties[RDConstants.promoActionID] = actId
        if !self.subsEmail.isEmptyOrWhitespace {
            properties[RDConstants.promoEmailKey] = email
        }
        properties[RDConstants.promoTitleKey] = promoTitle
        if !self.sliceText.isEmptyOrWhitespace {
            properties[RDConstants.promoSlice] = promoSlice
        }
        RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
    }

    override func show(animated: Bool) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication() else {
            return
        }
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first
            if let windowScene = windowScene as? UIWindowScene {
                window = UIWindow(frame: windowScene.coordinateSpace.bounds)
                window?.windowScene = windowScene
            }
        } else {
            window = UIWindow(frame: CGRect(x: 0,
                                            y: 0,
                                            width: UIScreen.main.bounds.size.width,
                                            height: UIScreen.main.bounds.size.height))
        }
        if let window = window {
            window.alpha = 0
            window.windowLevel = UIWindow.Level.alert
            window.rootViewController = self
            window.isHidden = false
        }

        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.window?.alpha = 1
        }, completion: { _ in
        })
    }

    override func hide(animated: Bool, completion: @escaping () -> Void) {
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.window?.alpha = 0
        }, completion: { _ in
            self.window?.isHidden = true
            self.window?.removeFromSuperview()
            self.window = nil
            completion()
        })
    }

    private func getCustomFontNames() -> Set<String> {
        var customFontNames = Set<String>()
        if let plinko = self.plinko {
            if !plinko.custom_font_family_ios.isEmptyOrWhitespace {
                customFontNames.insert(plinko.custom_font_family_ios)
            }
        }
        return customFontNames
    }

    private func createPlinkoFiles() -> URL? {
        let manager = FileManager.default
        guard let docUrl = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            RDLogger.error("Can not create documentDirectory")
            return nil
        }
        let htmlUrl = docUrl.appendingPathComponent("plinko.html")
        let jsUrl = docUrl.appendingPathComponent("plinko.js")
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: type(of: self))
#endif
        let bundleHtmlPath = bundle.path(forResource: "plinko", ofType: "html") ?? ""
        let bundleHtmlUrl = URL(fileURLWithPath: bundleHtmlPath)

        RDHelper.registerFonts(fontNames: getCustomFontNames())
        let fontUrls = getPlinkoFonts(fontNames: getCustomFontNames())

        do {
            if manager.fileExists(atPath: htmlUrl.path) {
                try manager.removeItem(atPath: htmlUrl.path)
            }
            if manager.fileExists(atPath: jsUrl.path) {
                try manager.removeItem(atPath: jsUrl.path)
            }

            try manager.copyItem(at: bundleHtmlUrl, to: htmlUrl)

            if let jsContent = plinko?.jsContent?.utf8 {
                guard manager.createFile(atPath: jsUrl.path, contents: Data(jsContent)) else {
                    return nil
                }
            } else {
                return nil
            }
        } catch let error {
            RDLogger.error(error)
            RDLogger.error(error.localizedDescription)
            return nil
        }

        for fontUrlKeyValue in fontUrls {
            do {
                let fontUrl = docUrl.appendingPathComponent(fontUrlKeyValue.key)
                if manager.fileExists(atPath: fontUrl.path) {
                    try manager.removeItem(atPath: fontUrl.path)
                }
                try manager.copyItem(at: fontUrlKeyValue.value, to: fontUrl)
                self.plinko?.fontFiles.append(fontUrlKeyValue.key)
            } catch let error {
                RDLogger.error(error)
                RDLogger.error(error.localizedDescription)
                continue
            }
        }

        return htmlUrl
    }

    private func getPlinkoFonts(fontNames: Set<String>) -> [String: URL] {
        var fontUrls = [String: URL]()
        if let infos = Bundle.main.infoDictionary {
            if let uiAppFonts = infos["UIAppFonts"] as? [String] {
                for uiAppFont in uiAppFonts {
                    let uiAppFontParts = uiAppFont.split(separator: ".")
                    guard uiAppFontParts.count == 2 else {
                        continue
                    }
                    let fontName = String(uiAppFontParts[0])
                    let fontExtension = String(uiAppFontParts[1])

                    var register = false
                    for name in fontNames {
                        if name.contains(fontName, options: .caseInsensitive) {
                            register = true
                        }
                    }

                    if !register {
                        continue
                    }

                    guard let url = Bundle.main.url(forResource: fontName, withExtension: fontExtension) else {
                        RDLogger.error("UIFont+:  Failed to register font - path for resource not found.")
                        continue
                    }
                    fontUrls[uiAppFont] = url
                }
            }
        }
        return fontUrls
    }
}

extension PlinkoViewController: WKScriptMessageHandler {

    private func chooseSlot(selectedIndex: Int, selectedPromoCode: String) {
        var promoCode = selectedPromoCode
        var index = selectedIndex

        if selectedIndex < 0 {
            if !sIndexCodes.isEmpty, let randomIndex = sIndexCodes.keys.randomElement(), let randomCode = sIndexCodes[randomIndex], let randomDisplay = sIndexDisplayNames[randomIndex] {
                self.sliceText = randomDisplay
                promoCode = randomCode
                index = randomIndex
            }
        }

        if index > -1 {
            if !self.subsEmail.isEmptyOrWhitespace {
                self.sendPromotionCodeInfo(promo: promoCode, actId: "act-\(self.plinko!.actId)", email: self.subsEmail, promoTitle: self.plinko?.promocodeTitle ?? "", promoSlice: self.sliceText)
            } else {
                self.sendPromotionCodeInfo(promo: promoCode, actId: "act-\(self.plinko!.actId)", promoTitle: self.plinko?.promocodeTitle ?? "", promoSlice: self.sliceText)
            }
        }
        let promoCodeString = index > -1 ? "'\(promoCode)'" : "undefined"

        DispatchQueue.main.async {
            self.sliceLink = self.sliceLinks[index]
            if index > -1 {
                self.codeGotten = true
                BannerCodeManager.shared.setPlinkoCode(code: promoCode)
                self.plinko?.bannerCode = promoCode
            }
            self.webView.evaluateJavaScript("window.choosePlinkoSlot(\(index), \(promoCodeString));") { (_, err) in
                if let error = err {
                    RDLogger.error(error)
                    RDLogger.error(error.localizedDescription)
                }
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if message.name == "eventHandler" {
            if let event = message.body as? [String: Any], let method = event["method"] as? String {

                if method == "console.log", let message = event["message"] as? String {
                    RDLogger.info("console.log: \(message)")
                }

                if method == "initPlinko" {
                    RDLogger.info("initPlinko")
                    if let jsonString = plinko?.jsonContent {
                        self.webView.evaluateJavaScript("window.initPlinko(\(jsonString));") { (_, err) in
                            if let error = err {
                                RDLogger.error(error)
                                RDLogger.error(error.localizedDescription)
                            }
                        }
                    }
                }

                if method == "subscribeEmail", let email = event["email"] as? String {
                    RelatedDigital.subscribePlinkoMail(actid: "\(self.plinko!.actId)", auth: self.plinko!.auth, mail: email)
                    subsEmail = email
                }

                if method == "getPromotionCode" {
                    var index = 0
                    for slice in plinko!.slices {
                        if slice.type == "promotion", slice.isAvailable {
                            pIndexCodes[index] = slice.code
                            pIndexDisplayNames[index] = slice.displayName
                        } else if slice.type == RDConstants.staticcode {
                            sIndexCodes[index] = slice.code
                            sIndexDisplayNames[index] = slice.displayName
                        }
                        sliceLinks[index] = slice.iosLink
                        index += 1
                    }

                    if !pIndexCodes.isEmpty, let randomIndex = pIndexCodes.keys.randomElement(), let randomCode = pIndexCodes[randomIndex], let randomDisplay = pIndexDisplayNames[randomIndex] {
                        var props = Properties()
                        props["actionid"] = "\(self.plinko!.actId)"
                        props["promotionid"] = randomCode
                        props["promoauth"] = "\(self.plinko!.promoAuth)"
                        self.sliceText = randomDisplay

                        RDRequest.sendPromotionCodeRequest(properties: props, completion: { (result: [String: Any]?, error: RDError?) in
                            var selectedIndex = randomIndex as Int
                            var selectedPromoCode = ""
                            if error == nil, let res = result, let success = res["success"] as? Bool, success, let promocode = res["promocode"] as? String, !promocode.isEmptyOrWhitespace {
                                selectedPromoCode = promocode
                            } else if let res = result, let success = res["success"] as? Bool, success, let promocode = res["promocode"] as? String {
                                let id = res["id"] as? Int ?? 0
                                RDLogger.error("Promocode request error: {\"id\":\(id),\"success\":\(success),\"promocode\":\"\(promocode)\"}")
                                selectedIndex = -1
                            } else {
                                RDLogger.error("Promocode request error")
                                selectedIndex = -1
                            }
                            self.chooseSlot(selectedIndex: selectedIndex, selectedPromoCode: selectedPromoCode)
                        })
                    } else {
                        self.chooseSlot(selectedIndex: -1, selectedPromoCode: "")
                    }
                }

                if method == "sendReport" {
                    RelatedDigital.trackPlinkoClick(plinkoReport: self.plinko!.report ?? PlinkoReport())
                }

                if method == "copyToClipboard", let couponCode = event["couponCode"] as? String {
                    UIPasteboard.general.string = couponCode
                    RDHelper.showCopiedClipboardMessage()
                    let sliceLink = event["sliceLink"]
                    NotificationCenter.default.post(name: Notification.Name(RDConstants.InAppLink), object: nil, userInfo: ["link": sliceLink ?? ""])
                    self.close()
                }

                if method == "close" {
                    self.sliceLink = nil
                    self.close()
                }

                if method == "openUrl", let urlString = event["url"] as? String, let url = URL(string: urlString) {
                    let app = RDInstance.sharedUIApplication()
                    app?.performSelector(onMainThread: NSSelectorFromString("openURL:"), with: url, waitUntilDone: true)
                }
            }
        }
    }
}
