//
//  GiftBoxViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 23.01.2023.
//

import UIKit
import WebKit

class GiftBoxViewController: RDBaseNotificationViewController {

    weak var webView: WKWebView!
    var subsEmail = ""
    var codeGotten = false

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = configureWebView()
        self.view.addSubview(webView)
        webView.allEdges(to: self.view)
    }

    init(_ giftBox: GiftBoxModel) {
        super.init(nibName: nil, bundle: nil)
        self.giftBox = giftBox
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func close() {
        dismiss(animated: true) {
            if let giftBox = self.giftBox, !giftBox.promocode_banner_button_label.isEmptyOrWhitespace, self.codeGotten == true {
                if giftBox.bannercodeShouldShow ?? false {
                    let bannerVC = RDGiftBoxCodeBannerController(giftBox)
                    bannerVC.delegate = self.delegate
                    bannerVC.show(animated: true)
                }
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            } else {
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            }
        }
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

    func configureWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "eventHandler")
        configuration.userContentController = userContentController
        configuration.preferences.javaScriptEnabled = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if let htmlUrl = createGiftBoxFiles() {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
            webView.backgroundColor = .clear
            webView.translatesAutoresizingMaskIntoConstraints = false
        }

        return webView
    }

    private func createGiftBoxFiles() -> URL? {
        let manager = FileManager.default
        guard let docUrl = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            RDLogger.error("Can not create documentDirectory")
            return nil
        }
        let htmlUrl = docUrl.appendingPathComponent("giftboxDoc.html")
        let jsUrl = docUrl.appendingPathComponent("giftbox.js")
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: type(of: self))
#endif
        let bundleHtmlPath = bundle.path(forResource: "giftboxDoc", ofType: "html") ?? ""

        let bundleHtmlUrl = URL(fileURLWithPath: bundleHtmlPath)

        RDHelper.registerFonts(fontNames: getCustomFontNames())
        let fontUrls = giftBoxFonts(fontNames: getCustomFontNames())

        do {
            if manager.fileExists(atPath: htmlUrl.path) {
                try manager.removeItem(atPath: htmlUrl.path)
            }
            if manager.fileExists(atPath: jsUrl.path) {
                try manager.removeItem(atPath: jsUrl.path)
            }

            try manager.copyItem(at: bundleHtmlUrl, to: htmlUrl)

            if let jsContent = giftBox?.jsContent?.utf8 {
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
                self.giftBox?.fontFiles.append(fontUrlKeyValue.key)
            } catch let error {
                RDLogger.error(error)
                RDLogger.error(error.localizedDescription)
                continue
            }
        }

        return htmlUrl
    }

    private func giftBoxFonts(fontNames: Set<String>) -> [String: URL] {
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

    private func getCustomFontNames() -> Set<String> {
        var customFontNames = Set<String>()
        if let giftBox = self.giftBox {
            if !giftBox.custom_font_family_ios.isEmptyOrWhitespace {
                customFontNames.insert(giftBox.custom_font_family_ios)
            }
        }
        return customFontNames
    }

}

extension GiftBoxViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if message.name == "eventHandler" {
            if let event = message.body as? [String: Any], let method = event["method"] as? String {
                if method == "console.log", let message = event["message"] as? String {
                    RDLogger.info("console.log: \(message)")
                }

                if method == "initFindGame" {
                    RDLogger.info("initFindGame")
                    
                    if let jsonString = giftBox?.jsonContent {
                        self.webView.evaluateJavaScript("window.initFindGame(\(jsonString));") { (_, err) in
                            if let error = err {
                                RDLogger.error(error)
                                RDLogger.error(error.localizedDescription)

                            }
                        }
                    }
                }

                if method == "copyToClipboard", let couponCode = event["couponCode"] as? String, let codeUrl = event["url"] as? String {
                    UIPasteboard.general.string = couponCode
                    RDHelper.showCopiedClipboardMessage()
                    self.close()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        if let url = URL(string: codeUrl) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                if method == "subscribeEmail", let email = event["email"] as? String {
                    RelatedDigital.subscribeGiftBoxMail(actid: "\(self.giftBox!.actId ?? 0)", auth: self.giftBox!.auth, mail: email)
                    subsEmail = email
                }

                if method == "sendReport" {
                    RelatedDigital.trackGiftBoxClick(giftBoxReport: (self.giftBox?.report)!)
                }

                if method == "linkClicked", let urlLnk = event["url"] as? String {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        if let url = URL(string: urlLnk) {
                            UIApplication.shared.open(url)
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(RDConstants.InAppLink), object: nil, userInfo: ["link": urlLnk ])
                        }
                    }
                }

                if method == "saveCodeGotten", let code = event["code"] as? String, let mail = event["email"] as? String {
                    codeGotten = true
                    UIPasteboard.general.string = code
                    BannerCodeManager.shared.setGiftBoxCode(code: code)
                    let actionID = self.giftBox?.actId
                    var properties = Properties()
                    properties[RDConstants.promoActionID] = String(actionID ?? 0)
                    properties[RDConstants.promoEmailKey] = mail
                    properties[RDConstants.promoAction] = code
                    RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
                }

                if method == "close" {
                    self.close()
                }
            }
        }

    }

}
