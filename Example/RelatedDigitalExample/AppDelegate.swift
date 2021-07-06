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
        // Override point for customization after application launch.
        RelatedDigital.createAPI(organizationId: "orgID", profileId: "profId", dataSource: "dSo")
        RelatedDigital.callAPI().loggingEnabled = true
        return true
    }


}

