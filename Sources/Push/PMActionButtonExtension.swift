//
//  PMActionButtonExtension.swift
//  relatedDigital
//
//  Created by Orhun Akmil on 9.08.2022.
//

import Foundation
import UserNotifications
import UIKit

extension RDPush {
    
    @available(iOS 10.0, *)
    static func handleActionButton(_ data: Data?, _ response: UNNotificationResponse?) {
        
        guard let json = data, let response = response else {
            print(">>> no json exist")
            return
        }
        guard let message = try? JSONDecoder.init().decode(RDPushMessage.self, from: json) else {
            print(">>>json parse error")
            return
        }
        guard let buttons = message.actions else {
            print(">>> no buttons exist")
            return
        }
        
        for button in buttons where button.Title == response.actionIdentifier {
            print(">>> response.actionIdentifier ==> \(response.actionIdentifier)")
            print(">>> button.identifier ==> \(button.Title ?? "")")
            print(">>> button.link ==> \(button.Url ?? "")")
            guard let link = URL(string: button.Url ?? "") else { return }
            UIApplication.shared.open(link)
            //UIApplication.shared.openURL(link)
            
        }
        
    }
}

