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
    var isRelatedInit = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        RelatedDigital.initialize(organizationId: relatedDigitalProfile.organizationId, profileId: relatedDigitalProfile.profileId, dataSource: relatedDigitalProfile.dataSource, launchOptions: launchOptions)
        RelatedDigital.enablePushNotifications(appAlias: "RDIOSExample", launchOptions: launchOptions, appGroupsKey: "group.com.relateddigital.RelatedDigitalExample.relateddigital")
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

