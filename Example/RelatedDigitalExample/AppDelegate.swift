//
//  AppDelegate.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        RelatedDigital.createAPI(organizationId: "orgID", profileId: "profId", dataSource: "dSo")
        RelatedDigital.callAPI().loggingEnabled = true
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = HomeViewController() // Your initial view controller.
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    
}

