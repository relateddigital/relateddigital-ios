//
//  RelatedDigital.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.07.2020.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit
import UserNotifications

typealias Queue = [[String: String]]

struct RelatedDigitalUser: Codable {
    var cookieId: String?
    var exVisitorId: String?
    var tokenId: String?
    var appId: String?
    var visitData: String?
    var visitorData: String?
    var userAgent: String?
    var identifierForAdvertising: String?
    var sdkVersion: String?
    var lastEventTime: String?
    var nrv = 0
    var pviv = 0
    var tvc = 0
    var lvt: String?
    var appVersion: String?
}

struct RelatedDigitalProfile: Codable {
    var organizationId: String
    var profileId: String
    var dataSource: String
    var channel: String
    var requestTimeoutInSeconds: Int
    var geofenceEnabled: Bool
    var inAppNotificationsEnabled: Bool
    var maxGeofenceCount: Int
    var isIDFAEnabled: Bool
    var requestTimeoutInterval: TimeInterval {
        return TimeInterval(requestTimeoutInSeconds)
    }

    var useInsecureProtocol = false
}

class urlConstant {
    static var shared = urlConstant()
    var urlPrefix = "s.visilabs.net"
    var securityTag = "https"
    var organizationId = "676D325830564761676D453D"
    var profileId = "356467332F6533766975593D"
    
    func setTest() {
        urlPrefix = "tests.visilabs.net"
        securityTag = "http"
    }
}


/**
 * RelatedDigital manages the shared state for all RelatedDigital services. RelatedDigital.initialize should be
 * called from within your application delegate's `application:didFinishLaunchingWithOptions:` method
 * to initialize the shared instance.
 */


/// Main entry point for RelatedDigital. The application must call `initialize` during `application:didFinishLaunchingWithOptions:`
/// before accesing any instances on RelatedDigital.
public class RelatedDigital {
    
    var relatedDigitalInstance: RelatedDigitalInstanceProtocol
    
    static var _shared: RelatedDigital?
    
    public static var shared: RelatedDigital {
        if _shared == nil {
            assertionFailure("TakeOff must be called before accessing Airship.")
        }
        return _shared!
    }

    
    /// Initalizes RelatedDigital. The values of `organizationId`,`profileId`,`dataSource` could be obtained by
    /// [RelatedDigital Admin Panel](https://intelligence.relateddigital.com/#Management/UserManagement/Profiles) and selecting relevant profile.
    ///
    /// - Warning: Call this method from the main thread in your `AppDelegate` class before calling any other RelatedDigital methods.
    ///
    /// - Parameters:
    ///     - organizationId: The ID of your organization.
    ///     - profileId: The ID of the profile you want to integrate.
    ///     - dataSource: The data source of the profile you want to integrate.
    ///     - launchOptions: The launch options passed into `application:didFinishLaunchingWithOptions:`
    ///
    public class func initialize(organizationId: String, profileId: String, dataSource: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        
        guard Thread.isMainThread else {
            fatalError("initialize must be called on the main thread.")
        }
        
        guard _shared == nil else {
            RelatedDigitalLogger.error("initialize can only be called once.")
            return
        }
        
        if organizationId.isEmptyOrWhitespace || profileId.isEmptyOrWhitespace || dataSource.isEmptyOrWhitespace {
            fatalError("organizationId, profileId and dataSource must have value.")
        }
        
        _shared = RelatedDigital(instance: RelatedDigitalInstance(organizationId: organizationId, profileId: profileId, dataSource: dataSource))
        
    }
    
    init(instance: RelatedDigitalInstanceProtocol) {
        self.relatedDigitalInstance = instance
    }
    
    
    
    static var rdUser: RelatedDigitalUser { return shared.relatedDigitalInstance.rdUser }
    
    static var rdProfile: RelatedDigitalProfile { return shared.relatedDigitalInstance.rdProfile }
    
    
    public static var exVisitorId: String? { return shared.relatedDigitalInstance.exVisitorId }
    
    public static var locationServicesEnabledForDevice: Bool {
        return shared.relatedDigitalInstance.locationServicesEnabledForDevice
    }
    
    public static var locationServiceStateStatusForApplication: RelatedDigitalCLAuthorizationStatus {
        return shared.relatedDigitalInstance.locationServiceStateStatusForApplication
    }
    
    public static var inappButtonDelegate: RelatedDigitalInappButtonDelegate? {
        get {
            return shared.relatedDigitalInstance.inappButtonDelegate
        }
        set {
            shared.relatedDigitalInstance.inappButtonDelegate = newValue
        }
    }
    
    public static var loggingEnabled: Bool {
        get {
            return shared.relatedDigitalInstance.loggingEnabled
        }
        set {
            shared.relatedDigitalInstance.loggingEnabled = newValue
        }
    }
    
    public static var inAppNotificationsEnabled: Bool {
        get {
            return shared.relatedDigitalInstance.inAppNotificationsEnabled
        }
        set {
            shared.relatedDigitalInstance.inAppNotificationsEnabled = newValue
        }
    }
    
    public static var geofenceEnabled: Bool {
        get {
            return shared.relatedDigitalInstance.inAppNotificationsEnabled
        }
        set {
            shared.relatedDigitalInstance.inAppNotificationsEnabled = newValue
        }
    }
    
    public static func requestIDFA() {
        shared.relatedDigitalInstance.requestIDFA()
    }
    
    public static func sendLocationPermission() {
        shared.relatedDigitalInstance.sendLocationPermission()
    }
    
    public static func customEvent(_ pageName: String, properties: [String: String]) {
        shared.relatedDigitalInstance.customEvent(pageName, properties: properties)
    }
    
    public static func login(exVisitorId: String, properties: [String: String]) {
        shared.relatedDigitalInstance.login(exVisitorId: exVisitorId, properties: properties)
    }
    
    public static func signUp(exVisitorId: String, properties: [String: String]) {
        shared.relatedDigitalInstance.signUp(exVisitorId: exVisitorId, properties: properties)
    }
    
    public static func logout() {
        shared.relatedDigitalInstance.logout()
    }
    
    public static func getStoryView(actionId: Int? = nil, urlDelegate: RelatedDigitalStoryURLDelegate? = nil) -> RelatedDigitalStoryHomeView {
        shared.relatedDigitalInstance.getStoryView(actionId: actionId, urlDelegate: urlDelegate)
    }
    
    public static func getStoryViewAsync(actionId: Int? = nil, urlDelegate: RelatedDigitalStoryURLDelegate? = nil
                                  , completion: @escaping ((_ storyHomeView: RelatedDigitalStoryHomeView?) -> Void)) {
        shared.relatedDigitalInstance.getStoryViewAsync(actionId: actionId, urlDelegate: urlDelegate, completion: completion)
    }
    
    public static func recommend(zoneId: String,
                          productCode: String? = nil,
                          filters: [RelatedDigitalRecommendationFilter] = [],
                          properties: [String: String] = [:],
                          completion: @escaping ((_ response: RelatedDigitalRecommendationResponse) -> Void)){
        shared.relatedDigitalInstance.recommend(zoneId: zoneId, productCode: productCode, filters: filters,
                                                properties: properties, completion: completion)
    }
    
    public static func trackRecommendationClick(qs: String) {
        shared.relatedDigitalInstance.trackRecommendationClick(qs: qs)
    }
    
    public static func getFavoriteAttributeActions(actionId: Int? = nil,
                                            completion: @escaping ((_ response: RelatedDigitalFavoriteAttributeActionResponse)
                                                                   -> Void)) {
        shared.relatedDigitalInstance.getFavoriteAttributeActions(actionId: actionId, completion: completion)
    }

    static func showNotification(_ relatedDigitalInAppNotification: RelatedDigitalInAppNotification) {
        shared.relatedDigitalInstance.showNotification(relatedDigitalInAppNotification)
    }
    
    static func subscribeSpinToWinMail(actid: String, auth: String, mail: String) {
        shared.relatedDigitalInstance.subscribeSpinToWinMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeMail(click: String, actid: String, auth: String, mail: String) {
        shared.relatedDigitalInstance.subscribeMail(click: click, actid: actid, auth: auth, mail: mail)
    }
    
    static func trackSpinToWinClick(spinToWinReport: SpinToWinReport) {
        shared.relatedDigitalInstance.trackSpinToWinClick(spinToWinReport: spinToWinReport)
    }
}
