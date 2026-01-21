//
//  AppDelegate.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import RelatedDigitalIOS
import UIKit
import UserNotifications

var relatedDigitalProfile = RelatedDigitalProfile()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var window: UIWindow?
    var isRelatedInit = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if UrlConstant.shared.getTestWithLocalData() {
            UrlConstant.shared.setTest()
        }
        RelatedDigital.start(launchOptions: nil)
        RelatedDigital.loggingEnabled = true
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = SelectViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    func getTabBarController() -> RelatedDigitalTabBarController {
        return RelatedDigitalTabBarController()
    }
    
    func getPushViewController() -> PushViewController {
        return PushViewController()
    }
    
    func getHomeViewController() -> HomeViewController {
        return HomeViewController()
    }
}
