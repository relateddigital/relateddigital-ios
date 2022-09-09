//
//  gameficationViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 18.04.2022.
//

import UIKit
import WebKit

class GameficationViewController: RDBaseNotificationViewController {
    
    weak var webView: WKWebView!
    var subsEmail = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = configureWebView()
        self.view.addSubview(webView)
        webView.allEdges(to: self.view)
    }
    
    init(_ gamefication : GameficationViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.gameficationModel = gamefication
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func close() {
        dismiss(animated: true) {
            if let gamefication = self.gameficationModel {
                let bannerVC = RDGamificationCodeBannerController(gamefication)
                bannerVC.delegate = self.delegate
                bannerVC.show(animated: true)
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            } else {
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            }
        }
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
        if let htmlUrl = createGameficationFiles() {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
            webView.backgroundColor = .clear
            webView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        return webView
    }
    
    private func createGameficationFiles() -> URL? {
        let manager = FileManager.default
        guard let docUrl = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            RDLogger.error("Can not create documentDirectory")
            return nil
        }
        let htmlUrl = docUrl.appendingPathComponent("gift_catch_index.html")
        let jsUrl = docUrl.appendingPathComponent("gift_catch.js")
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: type(of: self))
#endif
        let bundleHtmlPath = bundle.path(forResource: "gift_catch_index", ofType: "html") ?? ""
        let bundleJsPath = bundle.path(forResource: "gift_catch", ofType: "js") ?? ""

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

extension GameficationViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "eventHandler" {
            if let event = message.body as? [String: Any], let method = event["method"] as? String {
                if method == "console.log", let message = event["message"] as? String {
                    RDLogger.info("console.log: \(message)")
                }
                
                if method == "initGiftCatch" {
                    RDLogger.info("initGiftCatch")
                    //burada spintowinModelı kaldı düzeltilmeli
                    if let json = try? JSONEncoder().encode(self.gameficationModel), let jsonString = String(data: json, encoding: .utf8) {
                        print(jsonString)
                        self.webView.evaluateJavaScript("window.initGiftCatch(\(jsonString));") { (_, err) in
                            if let error = err {
                                RDLogger.error(error)
                                RDLogger.error(error.localizedDescription)
                                
                            }
                        }
                    }
                }
                
                if method == "copyToClipboard", let couponCode = event["couponCode"] as? String {
                    UIPasteboard.general.string = couponCode
                    RDHelper.showCopiedClipboardMessage()
                    self.close()
                }
                
                if method == "subscribeEmail", let email = event["email"] as? String {
                    RelatedDigital.subscribeGamificationMail(actid: "\(self.gameficationModel!.actId ?? 0)", auth: self.gameficationModel!.auth, mail: email)
                    subsEmail = email
                }
                
                if method == "sendReport" {
                    RelatedDigital.trackGamificationClick(gameficationReport: self.gameficationModel!.report!)
                }
                
                if method == "close" {
                    self.close()
                }
            }
        }
        
    }
    
}
