//
//  RelatedDigital.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.07.2021.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit
import UserNotifications


/**
 * RelatedDigital manages the shared state for all RelatedDigital services. RelatedDigital.initialize should be
 * called from within your application delegate's `application:didFinishLaunchingWithOptions:` method
 * to initialize the shared instance.
 */


/// Main entry point for RelatedDigital. The application must call `initialize` during `application:didFinishLaunchingWithOptions:`
/// before accesing any instances on RelatedDigital.
public class RelatedDigital {
    
    var rdInstance: RDInstanceProtocol
    
    static var _shared: RelatedDigital?
    static var initializeCalled = false;
    
    public static var shared: RelatedDigital {
        if _shared == nil {
            assertionFailure("initialize must be called before accessing RelatedDigital.")
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
        
        initializeCalled = true
        
        guard _shared == nil else {
            RDLogger.error("initialize can only be called once.")
            return
        }
        
        if organizationId.isEmptyOrWhitespace || profileId.isEmptyOrWhitespace || dataSource.isEmptyOrWhitespace {
            fatalError("organizationId, profileId and dataSource must have value.")
        }
        
        _shared = RelatedDigital(instance: RDInstance(organizationId: organizationId, profileId: profileId, dataSource: dataSource))
        
    }
    
    class func initialize() {
        initializeCalled = true
        guard _shared == nil else {
            RDLogger.error("initialize can only be called once.")
            return
        }
        if let rdInstance = RDInstance() {
            _shared = RelatedDigital(instance: rdInstance)
        }
    }
    
    init(instance: RDInstanceProtocol) {
        self.rdInstance = instance
    }
    
    static var rdUser: RDUser { return shared.rdInstance.rdUser }
    
    static var rdProfile: RDProfile { return shared.rdInstance.rdProfile }
    
    public static var exVisitorId: String? { return shared.rdInstance.exVisitorId }
    
    public static var locationServicesEnabledForDevice: Bool {
        return shared.rdInstance.locationServicesEnabledForDevice
    }
    
    public static var locationServiceStateStatusForApplication: RDCLAuthorizationStatus {
        return shared.rdInstance.locationServiceStateStatusForApplication
    }
    
    public static var inappButtonDelegate: RDInappButtonDelegate? {
        get {
            return shared.rdInstance.inappButtonDelegate
        }
        set {
            shared.rdInstance.inappButtonDelegate = newValue
        }
    }
    
    public static var loggingEnabled: Bool {
        get {
            return shared.rdInstance.loggingEnabled
        }
        set {
            shared.rdInstance.loggingEnabled = newValue
        }
    }
    
    public static var inAppNotificationsEnabled: Bool {
        get {
            return shared.rdInstance.inAppNotificationsEnabled
        }
        set {
            shared.rdInstance.inAppNotificationsEnabled = newValue
        }
    }
    
    public static var geofenceEnabled: Bool {
        get {
            return shared.rdInstance.geofenceEnabled
        }
        set {
            shared.rdInstance.geofenceEnabled = newValue
        }
    }
    
    public static var askLocationPermmissionAtStart: Bool {
        get {
            return shared.rdInstance.askLocationPermmissionAtStart
        }
        set {
            shared.rdInstance.askLocationPermmissionAtStart = newValue
        }
    }
    
    public static func requestIDFA() {
        shared.rdInstance.requestIDFA()
    }
    
    public static func sendLocationPermission() {
        shared.rdInstance.sendLocationPermission()
    }
    
    public static func sendCampaignParameters(properties: Properties) {
        shared.rdInstance.sendCampaignParameters(properties: properties)
    }
    
    public static func customEvent(_ pageName: String, properties: Properties) {
        shared.rdInstance.customEvent(pageName, properties: properties)
    }
    
    public static func login(exVisitorId: String, properties: Properties) {
        shared.rdInstance.login(exVisitorId: exVisitorId, properties: properties)
    }
    
    public static func signUp(exVisitorId: String, properties: Properties) {
        shared.rdInstance.signUp(exVisitorId: exVisitorId, properties: properties)
    }
    
    public static func logout() {
        shared.rdInstance.logout()
    }
    
    public static func getStoryView(actionId: Int? = nil, urlDelegate: RDStoryURLDelegate? = nil) -> RDStoryHomeView {
        shared.rdInstance.getStoryView(actionId: actionId, urlDelegate: urlDelegate)
    }
    
    public static func getStoryViewAsync(actionId: Int? = nil, urlDelegate: RDStoryURLDelegate? = nil, completion: @escaping StoryCompletion) {
        shared.rdInstance.getStoryViewAsync(actionId: actionId, urlDelegate: urlDelegate, completion: completion)
    }
    
    public static func recommend(zoneId: String, productCode: String? = nil, filters: [RDRecommendationFilter] = [], properties: Properties = [:], completion: @escaping RecommendCompletion){
        shared.rdInstance.recommend(zoneId: zoneId, productCode: productCode, filters: filters, properties: properties, completion: completion)
    }
    
    public static func trackRecommendationClick(qs: String) {
        shared.rdInstance.trackRecommendationClick(qs: qs)
    }
    
    public static func getFavoriteAttributeActions(actionId: Int? = nil, completion: @escaping FavoriteAttributeActionCompletion) {
        shared.rdInstance.getFavoriteAttributeActions(actionId: actionId, completion: completion)
    }

    static func showNotification(_ relatedDigitalInAppNotification: RDInAppNotification) {
        shared.rdInstance.showNotification(relatedDigitalInAppNotification)
    }
    
    static func subscribeSpinToWinMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeSpinToWinMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeGamificationMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeGamificationMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeMail(click: String, actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeMail(click: click, actid: actid, auth: auth, mail: mail)
    }
    
    static func trackSpinToWinClick(spinToWinReport: SpinToWinReport) {
        shared.rdInstance.trackSpinToWinClick(spinToWinReport: spinToWinReport)
    }
    
    static func trackGamificationClick(gameficationReport: GameficationReport) {
        shared.rdInstance.trackGamificationClick(gameficationReport: gameficationReport)
    }
    
    
    // MARK: - Push
    
    public static func enablePushNotifications(appAlias: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil, appGroupsKey: String? = nil) {
        shared.rdInstance.enablePushNotifications(appAlias: appAlias, launchOptions: launchOptions, appGroupsKey: appGroupsKey)
    }
    
    public static func askForNotificationPermission(register: Bool = false) {
        shared.rdInstance.askForNotificationPermission(register: register)
    }
    
    public static func askForNotificationPermissionProvisional(register: Bool = false) {
        shared.rdInstance.askForNotificationPermissionProvisional(register: register)
    }
    
    public static func registerForPushNotifications() {
        shared.rdInstance.registerForPushNotifications()
    }
    
    public static func setPushNotification(permission: Bool) {
        shared.rdInstance.setPushNotification(permission: permission)
    }
    
    public static func setPhoneNumber(msisdn: String? = nil, permission: Bool) {
        shared.rdInstance.setPhoneNumber(msisdn: msisdn, permission: permission)
    }
    
    public static func setEmail(email: String? = nil, permission: Bool) {
        shared.rdInstance.setEmail(email: email, permission: permission)
    }
    
    public static func setEmail(email: String?) {
        shared.rdInstance.setEmail(email: email)
    }
    
    public static func setEuroUserId(userKey: String?) {
        shared.rdInstance.setEuroUserId(userKey: userKey)
    }
    
    public static func setAppVersion(appVersion: String?) {
        shared.rdInstance.setAppVersion(appVersion: appVersion)
    }
    
    public static func setTwitterId(twitterId: String?) {
        shared.rdInstance.setTwitterId(twitterId: twitterId)
    }
    
    public static func setAdvertisingIdentifier(adIdentifier: String?) {
        shared.rdInstance.setAdvertisingIdentifier(adIdentifier: adIdentifier)
    }
    
    public static func setFacebook(facebookId: String?) {
        shared.rdInstance.setFacebook(facebookId: facebookId)
    }
    
    public static func setUserProperty(key: String, value: String?) {
        shared.rdInstance.setUserProperty(key: key, value: value)
    }
    
    public static func removeUserProperty(key: String) {
        shared.rdInstance.removeUserProperty(key: key)
    }
    
    public static func setBadge(count: Int) {
        shared.rdInstance.setBadge(count: count)
    }
    
    public static func registerToken(tokenData: Data?) {
        shared.rdInstance.registerToken(tokenData: tokenData)
    }
    
    public static func handlePush(pushDictionary: [AnyHashable: Any]) {
        shared.rdInstance.handlePush(pushDictionary: pushDictionary)
    }
    
    public static func sync(notification: Notification? = nil) {
        shared.rdInstance.sync(notification: notification)
    }
    
    public static func registerEmail(email: String, permission: Bool, isCommercial: Bool = false, customDelegate: RDPushDelegate? = nil) {
        shared.rdInstance.registerEmail(email: email, permission: permission, isCommercial: isCommercial, customDelegate: customDelegate)
    }
    
    public static func getPushMessages(completion: @escaping GetPushMessagesCompletion) {
        shared.rdInstance.getPushMessages(completion: completion)
    }
    
//    private func showDownhs() ->Bool {
//        let downhsViewController = downHsViewController(model: downHsModel())
//        //downhsViewController.delegate = self
//        downhsViewController.show(animated: true)
//        return true
//    }
    
}
