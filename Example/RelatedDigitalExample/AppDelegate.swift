//
//  AppDelegate.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS

var relatedDigitalProfile = RelatedDigitalProfile()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        RelatedDigital.initialize(organizationId: "676D325830564761676D453D", profileId: "356467332F6533766975593D",
                                  dataSource: "visistore", launchOptions: launchOptions)
        RelatedDigital.loggingEnabled = true
        RelatedDigital.inAppNotificationsEnabled = true
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = HomeViewController() // Your initial view controller.
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    func getTabBarController() -> RelatedDigitalTabBarController {
        return RelatedDigitalTabBarController()
    }
    
    
}

