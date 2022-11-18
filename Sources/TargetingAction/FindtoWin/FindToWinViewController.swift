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
        var webView = WKWebView(frame: .zero, configuration: configuration)
        laodFindToWinFiles(webView: webView) { webViewAdded in
            webView = webViewAdded
        }
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
    
        return webView
    }
    
    
    func laodFindToWinFiles(webView:WKWebView,complete:@escaping(WKWebView)->Void) {
        
        var javaScriptStr = ""
        var htmlStr = ""
        
        let url = URL(string: RDConstants.findToWinUrl)!
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
        
        if let  htmlFile = bundle.path(forResource: "find_to_win", ofType: "html") {
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
