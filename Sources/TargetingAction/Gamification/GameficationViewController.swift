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
    var codeGotten = false


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
            
            if let gamefication = self.gameficationModel, !gamefication.promocode_banner_button_label.isEmptyOrWhitespace , self.codeGotten == true {
                let bannerVC = RDGamificationCodeBannerController(gamefication)
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
        var webView = WKWebView(frame: .zero, configuration: configuration)
        laodGiftRainFiles(webView: webView) { webViewAdded in
            webView = webViewAdded
        }
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        return webView
    }
    
    func laodGiftRainFiles(webView:WKWebView,complete:@escaping(WKWebView)->Void) {
        
        var javaScriptStr = ""
        var htmlStr = ""
        
        let url = URL(string: RDConstants.giftCatchUrl)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("data is nil")
                return
            }
            guard let text = String(data: data, encoding: .utf8) else {
                print("the response is not in UTF-8")
                return
            }
            
            javaScriptStr = text
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: type(of: self))
#endif
        
        if let  htmlFile = bundle.path(forResource: "gift_catch", ofType: "html") {
            htmlStr = try! String(contentsOfFile: htmlFile, encoding: String.Encoding.utf8)
        }

            DispatchQueue.main.async {
                let script = WKUserScript(source: javaScriptStr, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(script)
                webView.loadHTMLString(htmlStr, baseURL: nil)
            }
        }
        task.resume()
    
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
                    RelatedDigital.subscribeGamificationMail(actid: "\(self.gameficationModel!.actId ?? 0)", auth: self.gameficationModel!.auth, mail: email)
                    subsEmail = email
                }
                
                if method == "sendReport" {
                    RelatedDigital.trackGamificationClick(gameficationReport: self.gameficationModel!.report!)
                }
                
                if method == "linkClicked",let urlLnk = event["url"] as? String {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        if let url = URL(string: urlLnk) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                
                if method == "saveCodeGotten", let code = event["code"] as? String , let mail = event["email"] as? String {
                    codeGotten = true
                    UIPasteboard.general.string = code
                    BannerCodeManager.shared.setGiftRainCode(code: code)
                    let actionID = self.gameficationModel?.actId
                    
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
