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
    public class func initialize(organizationId: String, profileId: String, dataSource: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]?, askLocationPermmissionAtStart: Bool = true) {
        
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
        
        _shared = RelatedDigital(instance: RDInstance(organizationId: organizationId, profileId: profileId, dataSource: dataSource, askLocationPermissionAtStart: askLocationPermmissionAtStart))
        
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
    
    public static var rdUser: RDUser {
        return shared.rdInstance.rdUser
    }

    public static var rdProfile: RDProfile {
        return shared.rdInstance.rdProfile
    }
    
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
            return shared.rdInstance.askLocationPermissionAtStart
        }
        set {
            shared.rdInstance.askLocationPermissionAtStart = newValue
        }
    }
    
    public static func requestIDFA() {
        shared.rdInstance.requestIDFA()
    }
    
    public static func sendLocationPermission() {
        shared.rdInstance.sendLocationPermission()
    }
    
    public static func requestLocationPermissions() {
        shared.rdInstance.requestLocationPermissions()
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
    
    static func subscribeFindToWinMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeFindToWinMail(actid: actid, auth: auth, mail: mail)
    }
    static func subscribeGiftBoxMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeFindToWinMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeJackpotMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeJackpotMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeClawMachineMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeClowMachineMail(actid: actid, auth: auth, mail: mail)
    }
    
    static func subscribeChooseFavoriteMail(actid: String, auth: String, mail: String) {
        shared.rdInstance.subscribeChooseFavoriteMail(actid: actid, auth: auth, mail: mail)
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
    
    static func trackFindToWinClick(findToWinReport: FindToWinReport) {
        shared.rdInstance.trackFindToWinClick(findToWinReport: findToWinReport)
    }
    
    static func trackGiftBoxClick(giftBoxReport: GiftBoxReport) {
        shared.rdInstance.trackGiftBoxClick(giftBoxReport: giftBoxReport)
    }
    
    static func trackScratchToWinClick(scratchToWinReport: TargetingActionReport) {
        shared.rdInstance.trackScratchToWinClick(scratchToWinReport: scratchToWinReport)
    }
    
    static func trackJackpotClick(jackpotReport: JackpotReport) {
        shared.rdInstance.trackJackpotClick(jackpotReport: jackpotReport)
    }
    
    static func trackClawMachineClick(clawMachinetReport: ClawMachineReport) {
        shared.rdInstance.trackClowMachineClick(clowMachineReport: clawMachinetReport)
    }
    
    static func trackChooseFavoriteClick(chooseFavoriteReport: ChooseFavoriteReport) {
        shared.rdInstance.trackChooseFavoriteClick(chooseFavoriteReport: chooseFavoriteReport)
    }
    
    static func trackCustomWebviewClick(customWebviewReport: CustomWebViewReport) {
        shared.rdInstance.trackCustomWebviewClick(customWebviewReport: customWebviewReport)
    }
    
    // MARK: - Push
    
    public static func enablePushNotifications(appAlias: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil, appGroupsKey: String? = nil, deliveredBadge: Bool? = true) {
        shared.rdInstance.enablePushNotifications(appAlias: appAlias, launchOptions: launchOptions, appGroupsKey: appGroupsKey, deliveredBadge: deliveredBadge)
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
    
    public static func setAnonymous(permission: Bool) {
        shared.rdInstance.setAnonymous(permission: permission)
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
    
    public static func handlePushWithActionButtons(response:UNNotificationResponse,type:Any) {
        shared.rdInstance.handlePushWithActionButtons(response: response,type:type)
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
    
    public static func getPushMessagesWithID(completion: @escaping GetPushMessagesCompletion) {
        shared.rdInstance.getPushMessagesWithID(completion: completion)
    }
    
    public static func readAllPushMessages(pushId: String? = nil, completion: @escaping ((_ success: Bool) -> Void)) {
        if let pushId = pushId {
            shared.rdInstance.readAllPushMessagesWithId(pushId: pushId, completion: completion)
        } else {
            shared.rdInstance.readAllPushMessages(completion: completion)
        }
    }
    
    public static func getToken(completion: @escaping ((_ token: String) -> Void)) {
        shared.rdInstance.getToken(completion: completion)
    }

    public static func setNotificationLoginID(notificationLoginID: String?) {
        setUserProperty(key: PushKey.notificationLoginIdKey, value: notificationLoginID)
        PushUserDefaultsUtils.saveUserDefaults(key: PushKey.notificationLoginIdKey, value: notificationLoginID as AnyObject)
    }
    
    public static func getBannerView(properties: Properties,completion: @escaping (BannerView?) -> Void) {
        shared.rdInstance.getBannerView(properties: properties) { bannerView in
            bannerView?.reloadBannerViewData()
            completion(bannerView)
        }
    }
    
    public static func getButtonCarouselView(properties: Properties,completion: @escaping (ButtonCarouselView?) -> Void) {
        shared.rdInstance.getButtonCarouselView(properties: properties) { buttonCarouselView in
            completion(buttonCarouselView)
        }
    }
    
    public static func getNpsWithNumbersView(properties: Properties, delegate: RDNpsWithNumbersDelegate?, completion: @escaping (RDNpsWithNumbersContainerView?) -> Void) {
        shared.rdInstance.getNpsWithNumbersView(properties: properties, delegate: delegate) { npsWithNumbersView in
            completion(npsWithNumbersView)
        }
    }
    
    public static func deleteNotifications() {
        shared.rdInstance.deleteNotifications()
    }
    
    public static func removeNotification(withPushID pushID: String, completion: @escaping (Bool) -> Void) {
        shared.rdInstance.removeNotification(withPushID: pushID, completion: { deleted in
            completion(deleted)
        })
    }
    
    public static func trackSearchRecommendationClick(searchReport:Report) {
        var properties = [String: String]()
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = searchReport.click.parseClick().omZn
        properties["OM.zpc"] = searchReport.click.parseClick().omZpc
        customEvent(RDConstants.omEvtGif, properties: properties)
    }
    
    static func trackDrawerClick(drawerReport: DrawerReport) {
        shared.rdInstance.trackDrawerClick(drawerReport: drawerReport)
    }
}
