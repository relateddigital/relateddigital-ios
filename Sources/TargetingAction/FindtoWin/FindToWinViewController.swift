//
//  FindToWinViewController.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 29.06.2022.
//

import UIKit
import WebKit

class FindToWinViewController: RDBaseNotificationViewController {
    weak var webView: WKWebView!
    var subsEmail = ""
    var codeGotten = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = configureWebView()
        self.view.addSubview(webView)
        webView.allEdges(to: self.view)
    }
    
    init(_ findToWin : FindToWinViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.findToWin = findToWin
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func close() {
        dismiss(animated: true) {
            if let findToWin = self.findToWin, !findToWin.promocode_banner_button_label.isEmptyOrWhitespace , self.codeGotten == true {
                let bannerVC = RDFindToWinCodeBannerController(findToWin)
                bannerVC.delegate = self.delegate
                bannerVC.show(animated: true)
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
        if let htmlUrl = createFindToWinFiles() {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
            webView.backgroundColor = .clear
            webView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        return webView
    }
    
    private func createFindToWinFiles() -> URL? {
        let manager = FileManager.default
        guard let docUrl = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            RDLogger.error("Can not create documentDirectory")
            return nil
        }
        let htmlUrl = docUrl.appendingPathComponent("find_to_win.html")
        let jsUrl = docUrl.appendingPathComponent("find_to_win.js")
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: type(of: self))
#endif
        let bundleHtmlPath = bundle.path(forResource: "find_to_win", ofType: "html") ?? ""
        let bundleJsPath = bundle.path(forResource: "find_to_win", ofType: "js") ?? ""

        let bundleHtmlUrl = URL(fileURLWithPath: bundleHtmlPath)
        let bundleJsUrl = URL(fileURLWithPath: bundleJsPath)
        
//        RDHelper.registerFonts(fontNames: getCustomFontNames())
//        let fontUrls = getSpinToWinFonts(fontNames: getCustomFontNames())

        do {
            if manager.fileExists(atPath: htmlUrl.path) {
                try manager.removeItem(atPath: htmlUrl.path)
            }
            if manager.fileExists(atPath: jsUrl.path) {
                try manager.removeItem(atPath: jsUrl.path)
            }
            
            try manager.copyItem(at: bundleHtmlUrl, to: htmlUrl)
            try manager.copyItem(at: bundleJsUrl, to: jsUrl)
        } catch let error {
            RDLogger.error(error)
            RDLogger.error(error.localizedDescription)
            return nil
        }
        
//        for fontUrlKeyValue in fontUrls {
//            do {
//                let fontUrl = docUrl.appendingPathComponent(fontUrlKeyValue.key)
//                if manager.fileExists(atPath: fontUrl.path) {
//                    try manager.removeItem(atPath: fontUrl.path)
//                }
//                try manager.copyItem(at: fontUrlKeyValue.value, to: fontUrl)
//                self.spinToWin?.fontFiles.append(fontUrlKeyValue.key)
//            } catch let error {
//                RDLogger.error(error)
//                RDLogger.error(error.localizedDescription)
//                continue
//            }
//        }
        
        return htmlUrl
    }


}




extension FindToWinViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "eventHandler" {
            if let event = message.body as? [String: Any], let method = event["method"] as? String {
                if method == "console.log", let message = event["message"] as? String {
                    RDLogger.info("console.log: \(message)")
                }
                
                if method == "initFindGame" {
                    RDLogger.info("initFindGame")
                    //burada spintowinModelı kaldı düzeltilmeli
                    if let json = try? JSONEncoder().encode(self.findToWin!), let jsonString = String(data: json, encoding: .utf8) {
                        print(jsonString)
                        self.webView.evaluateJavaScript("window.initFindGame(\(jsonString));") { (_, err) in
                            if let error = err {
                                RDLogger.error(error)
                                RDLogger.error(error.localizedDescription)
                                
                            }
                        }
                    }
                }
                
                if method == "copyToClipboard", let couponCode = event["couponCode"] as? String,let codeUrl = event["url"] as? String {
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
                    RelatedDigital.subscribeFindToWinMail(actid: "\(self.findToWin!.actId ?? 0)", auth: self.findToWin!.auth, mail: email)
                    subsEmail = email
                }
                
                if method == "sendReport" {
                    RelatedDigital.trackFindToWinClick(findToWinReport: (self.findToWin?.report)!)
                }
                
                if method == "linkClicked",let urlLnk = event["url"] as? String {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        if let url = URL(string: urlLnk) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if method == "saveCodeGotten", let code = event["email"] as? String {
                    codeGotten = true
                    UIPasteboard.general.string = code
                    BannerCodeManager.shared.setFindToWinCode(code: code)
                }
                
                if method == "close" {
                    self.close()
                }
            }
        }
        
    }
    
}
