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

        // Do any additional setup after loading the view.
    }
    
    private func close() {
        dismiss(animated: true) {
            self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
        }
    }



}

extension GameficationViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "eventHandler" {
            if let event = message.body as? [String: Any], let method = event["method"] as? String {
                if method == "console.log", let message = event["message"] as? String {
                    RDLogger.info("console.log: \(message)")
                }
                
                if method == "copyToClipboard", let couponCode = event["couponCode"] as? String {
                    UIPasteboard.general.string = couponCode
                    RDHelper.showCopiedClipboardMessage()
                    self.close()
                }
                
                if method == "subscribeEmail", let email = event["email"] as? String {
                    RelatedDigital.subscribeGamificationMail(actid: "\(self.gameficationModel!.actId)", auth: self.gameficationModel!.auth, mail: email)
                    subsEmail = email
                }
                
                if method == "sendReport" {
                    RelatedDigital.trackGamificationClick(gameficationReport: self.gameficationModel!.report)
                }
                
                if method == "close" {
                    self.close()
                }
            }
        }
        
    }
    
}
