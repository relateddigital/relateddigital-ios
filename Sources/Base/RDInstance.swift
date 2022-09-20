//
//  RDInstance.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.10.2021.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit
import UserNotifications

public class RDInstance: RDInstanceProtocol {
    
    var exVisitorId: String? { return rdUser.exVisitorId }
    var rdUser = RDUser()
    var rdProfile: RDProfile
    var rdCookie = RDCookie()
    var eventsQueue = Queue()
    var trackingQueue: DispatchQueue!
    var targetingActionQueue: DispatchQueue!
    var recommendationQueue: DispatchQueue!
    var networkQueue: DispatchQueue!
    let readWriteLock: RDReadWriteLock
    private var observers: [NSObjectProtocol]? = []
    
    let rdEventInstance = RDEvent()
    let rdSendInstance = RDSend()
    let rdTargetingActionInstance: RDTargetingAction
    let rdRecommendationInstance = RDRecommendation()
    let rdRemoteConfigInstance: RDRemoteConfig
    let rdLocationManager: RDLocationManager
    
    var launchOptions: [UIA.LaunchOptionsKey : Any]? = nil
    
    static var deliveredBadgeCount: Bool?
    
    public var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                RDLogger.addLogging(RDPrintLogging())
                RDLogger.enableLevels([.debug, .info, .warning, .error])
                RDLogger.info("Logging Enabled")
            } else {
                RDLogger.info("Logging Disabled")
                RDLogger.disableLevels([.debug, .info, .warning, .error])
            }
        }
    }
    
    public var inAppNotificationsEnabled: Bool {
        get {
            return rdProfile.inAppNotificationsEnabled
        }
        set {
            rdProfile.inAppNotificationsEnabled = newValue
            RDPersistence.saveRDProfile(rdProfile)
        }
    }
    
    public var geofenceEnabled: Bool {
        get {
            return rdProfile.geofenceEnabled
        }
        set {
            rdProfile.geofenceEnabled = newValue
            RDPersistence.saveRDProfile(rdProfile)
        }
    }
    
    public var askLocationPermmissionAtStart: Bool {
        get {
            return rdProfile.askLocationPermmissionAtStart
        }
        set {
            rdProfile.askLocationPermmissionAtStart = newValue
            RDPersistence.saveRDProfile(rdProfile)
        }
    }
    
    public var useInsecureProtocol: Bool = false {
        didSet {
            rdProfile.useInsecureProtocol = useInsecureProtocol
            RDHelper.setEndpoints(dataSource: rdProfile.dataSource, useInsecureProtocol: useInsecureProtocol)
            RDPersistence.saveRDProfile(rdProfile)
        }
    }
    
    public weak var inappButtonDelegate: RDInappButtonDelegate?
    
    // swiftlint:disable function_body_length
    init(organizationId: String, profileId: String, dataSource: String, launchOptions: [UIA.LaunchOptionsKey : Any]? = nil) {
        
        rdProfile = RDPersistence.readRDProfile() ?? RDProfile(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
        rdProfile.organizationId = organizationId
        rdProfile.profileId = profileId
        rdProfile.dataSource = dataSource
        self.launchOptions = launchOptions
        
        RDPersistence.saveRDProfile(rdProfile)
        readWriteLock = RDReadWriteLock(label: "RDInstanceLock")
        let label = "com.relateddigital.\(rdProfile.profileId)"
        trackingQueue = DispatchQueue(label: "\(label).tracking)", qos: .utility)
        recommendationQueue = DispatchQueue(label: "\(label).recommendation)", qos: .utility)
        targetingActionQueue = DispatchQueue(label: "\(label).targetingaction)", qos: .utility)
        networkQueue = DispatchQueue(label: "\(label).network)", qos: .utility)
        rdTargetingActionInstance = RDTargetingAction(lock: readWriteLock, rdProfile: rdProfile)
        rdRemoteConfigInstance = RDRemoteConfig(profileId: rdProfile.profileId)
        rdLocationManager = RDLocationManager()
        
        RDHelper.setEndpoints(dataSource: rdProfile.dataSource)
        
        rdUser = unarchive()
        rdUser.sdkVersion = RDHelper.getSdkVersion()
        
        if let appVersion = RDHelper.getAppVersion() {
            rdUser.appVersion = appVersion
        }
        
        if rdUser.cookieId.isNilOrWhiteSpace {
            rdUser.cookieId = RDHelper.generateCookieId()
            RDPersistence.archiveUser(rdUser)
        }
        
        if rdProfile.isIDFAEnabled {
            RDHelper.getIDFA { uuid in
                if let idfa = uuid {
                    self.rdUser.identifierForAdvertising = idfa
                }
            }
        }
        
        rdTargetingActionInstance.inAppDelegate = self
        
        RDHelper.computeWebViewUserAgent { userAgentString in
            self.rdUser.userAgent = userAgentString
        }
        
        let ncd = NC.default
        observers = []
        
        if !RDHelper.isiOSAppExtension() {
            observers?.append(ncd.addObserver(forName: UIA.didBecomeActiveNotification, object: nil, queue: nil, using: self.applicationDidBecomeActive(_:)))
            observers?.append(ncd.addObserver(forName: UIA.willResignActiveNotification, object: nil, queue: nil, using: self.applicationWillResignActive(_:)))
        }
        
        if let appAlias = rdProfile.appAlias, !appAlias.isEmptyOrWhitespace, rdProfile.isPushNotificationEnabled {
            enablePushNotifications(appAlias: appAlias, launchOptions: self.launchOptions, appGroupsKey: rdProfile.appGroupsKey)
        }
        
    }
    
    convenience init?() {
        if let relatedDigitalProfile = RDPersistence.readRDProfile() {
            self.init(organizationId: relatedDigitalProfile.organizationId, profileId: relatedDigitalProfile.profileId, dataSource: relatedDigitalProfile.dataSource)
        } else {
            return nil
        }
    }
    
    deinit {
        NC.default.removeObserver(self, name: UIA.didBecomeActiveNotification, object: nil)
        NC.default.removeObserver(self, name: UIA.willResignActiveNotification, object: nil)
    }
    
    static func sharedUIApplication() -> UIA? {
        let shared = UIA.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue()
        guard let sharedApplication = shared as? UIA else {
            return nil
        }
        return sharedApplication
    }
}

// MARK: - IDFA

extension RDInstance {
    
    public func requestIDFA() {
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return
        }
        RDHelper.getIDFA { uuid in
            if let idfa = uuid {
                self.rdUser.identifierForAdvertising = idfa
                self.customEvent(RDConstants.omEvtGif, properties: Properties())
            }
        }
    }
    
}

// MARK: - EVENT

extension RDInstance {
    
    private func checkPushPermission() {
        let current = UNUNC.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus {
            case .authorized:
                RDConstants.pushPermitStatus = "granted"
            case .denied:
                RDConstants.pushPermitStatus = "denied"
            case .notDetermined:
                RDConstants.pushPermitStatus = "denied"
            case .provisional:
                RDConstants.pushPermitStatus = "default"
            case .ephemeral:
                RDConstants.pushPermitStatus = "denied"
            @unknown default:
                RDConstants.pushPermitStatus = "denied"
            }
        })
    }
    
    
    public func customEvent(_ pageName: String, properties: Properties) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if pageName.isEmptyOrWhitespace {
            RDLogger.error("customEvent can not be called with empty page name.")
            return
        }
        
        checkPushPermission()
        
        trackingQueue.async { [weak self, pageName, properties] in
            guard let self = self else { return }
            var eQueue = Queue()
            var user = RDUser()
            var chan = ""
            self.readWriteLock.read {
                (eQueue, user, chan) = (self.eventsQueue, self.rdUser, self.rdProfile.channel)
            }
            let result = self.rdEventInstance.customEvent(pageName: pageName, properties: properties, eventsQueue: eQueue, rdUser: user, channel: chan)
            self.readWriteLock.write {
                self.eventsQueue = result.eventsQueque
                self.rdUser = result.rdUser
                self.rdProfile.channel = result.channel
            }
            self.readWriteLock.read {
                RDPersistence.archiveUser(self.rdUser)
                if result.clearUserParameters {
                    RDPersistence.clearTargetParameters()
                }
            }
            if let event = self.eventsQueue.last {
                RDPersistence.saveTargetParameters(event)
                if RDBasePath.endpoints[.action] != nil, self.rdProfile.inAppNotificationsEnabled, pageName != RDConstants.omEvtGif {
                    self.checkInAppNotification(properties: event)
                    self.checkTargetingActions(properties: event)
                }
            }
            self.send()
        }
    }
    
    public func sendCampaignParameters(properties: Properties) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        trackingQueue.async { [weak self, properties] in
            guard let strongSelf = self else { return }
            var eQueue = Queue()
            var user = RDUser()
            var chan = ""
            strongSelf.readWriteLock.read {
                (eQueue, user, chan) = (strongSelf.eventsQueue, strongSelf.rdUser, strongSelf.rdProfile.channel)
            }
            let result = strongSelf.rdEventInstance.customEvent(properties: properties, eventsQueue: eQueue, rdUser: user, channel: chan)
            strongSelf.readWriteLock.write {
                strongSelf.eventsQueue = result.eventsQueque
                strongSelf.rdUser = result.rdUser
                strongSelf.rdProfile.channel = result.channel
            }
            strongSelf.readWriteLock.read {
                RDPersistence.archiveUser(strongSelf.rdUser)
                if result.clearUserParameters {
                    RDPersistence.clearTargetParameters()
                }
            }
            if let event = strongSelf.eventsQueue.last {
                RDPersistence.saveTargetParameters(event)
            }
            strongSelf.send()
        }
    }
    
    public func login(exVisitorId: String, properties: Properties = Properties()) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if exVisitorId.isEmptyOrWhitespace {
            RDLogger.error("login can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[RDConstants.exvisitorIdKey] = exVisitorId
        props["Login"] = exVisitorId
        props["OM.b_login"] = "Login"
        customEvent("LoginPage", properties: props)
    }
    
    public func signUp(exVisitorId: String, properties: Properties = Properties()) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if exVisitorId.isEmptyOrWhitespace {
            RDLogger.error("signUp can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[RDConstants.exvisitorIdKey] = exVisitorId
        props["SignUp"] = exVisitorId
        props["OM.b_sgnp"] = "SignUp"
        customEvent("SignUpPage", properties: props)
    }
    
    public func logout() {
        RDPersistence.clearUserDefaults()
        rdUser.cookieId = nil
        rdUser.exVisitorId = nil
        rdUser.cookieId = RDHelper.generateCookieId()
        RDPersistence.archiveUser(rdUser)
        RDPush.logout() //TODO: BUNA BAK SONRA
    }
    
}

// MARK: - PERSISTENCE

extension RDInstance {
    
    // TO_DO: kontrol et sıra doğru mu? gelen değerler null ise set'lemeli miyim?
    private func unarchive() -> RDUser {
        return RDPersistence.unarchiveUser()
    }
}

// MARK: - SEND

extension RDInstance {
    private func send() {
        trackingQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var eQueue = Queue()
                var user = RDUser()
                var rdCookie = RDCookie()
                self.readWriteLock.read {
                    (eQueue, user, rdCookie) = (self.eventsQueue, self.rdUser, self.rdCookie)
                }
                self.readWriteLock.write {
                    self.eventsQueue.removeAll()
                }
                let cookie = self.rdSendInstance.sendEventsQueue(eQueue, rdUser: user, rdCookie: rdCookie)
                self.readWriteLock.write {
                    self.rdCookie = cookie
                }
            }
        }
    }
}

// MARK: - TARGETING ACTIONS

// MARK: - Favorite Attribute Actions

extension RDInstance {
    public func getFavoriteAttributeActions(actionId: Int? = nil, completion: @escaping FavoriteAttributeActionCompletion) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            completion(RDFavoriteAttributeActionResponse(favorites: [RDFavoriteAttribute: [String]](), error: .noData))
            return
        }
        
        targetingActionQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var user = RDUser()
                self.readWriteLock.read {
                    user = self.rdUser
                }
                self.rdTargetingActionInstance.getFavorites(rdUser: user, actionId: actionId, completion: completion)
            }
        }
    }
}

// MARK: - InAppNotification

extension RDInstance: RDInAppNotificationsDelegate {
    
    // This method added for test purposes
    public func showNotification(_ rdInAppNotification: RDInAppNotification) {
        rdTargetingActionInstance.notificationsInstance.showNotification(rdInAppNotification)
    }
    
    public func showTargetingAction(_ model: TargetingActionViewModel) {
        rdTargetingActionInstance.notificationsInstance.showTargetingAction(model)
    }
    
    func checkInAppNotification(properties: Properties) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.checkInAppNotification(properties: properties, rdUser: self.rdUser, completion: { rdInAppNotification in
                    if let notification = rdInAppNotification {
                        self.rdTargetingActionInstance.notificationsInstance.inappButtonDelegate = self.inappButtonDelegate
                        self.rdTargetingActionInstance.notificationsInstance.showNotification(notification)
                    }
                })
            }
        }
    }
    
    func notificationDidShow(_ notification: RDInAppNotification) {
        rdUser.visitData = notification.visitData
        rdUser.visitorData = notification.visitorData
        RDPersistence.archiveUser(rdUser)
    }
    
    func trackNotification(_ notification: RDInAppNotification, event: String, properties: Properties) {
        if notification.queryString == nil || notification.queryString == "" {
            RDLogger.info("Notification or query string is nil or empty")
            return
        }
        let queryString = notification.queryString
        let qsArr = queryString!.components(separatedBy: "&")
        var properties = properties
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = qsArr[0].components(separatedBy: "=")[1]
        properties["OM.zpc"] = qsArr[1].components(separatedBy: "=")[1]
        customEvent(RDConstants.omEvtGif, properties: properties)
    }
    
    // İleride inapp de s.visilabs.net/mobile üzerinden geldiğinde sadece bu metod kullanılacak
    // checkInAppNotification metodu kaldırılacak.
    func checkTargetingActions(properties: Properties) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.checkTargetingActions(properties: properties, rdUser: self.rdUser, completion: { model in
                    if let targetingAction = model {
                        self.showTargetingAction(targetingAction)
                    }
                })
            }
        }
    }
    
    func subscribeSpinToWinMail(actid: String, auth: String, mail: String) {
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail, type: "spin_to_win_email")
    }
    
    func subscribeGamificationMail(actid: String, auth: String, mail: String) {
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail, type: "gamification_email")
    }
    
    func trackSpinToWinClick(spinToWinReport: SpinToWinReport) {
        var properties = Properties()
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = spinToWinReport.click.parseClick().omZn
        properties["OM.zpc"] = spinToWinReport.click.parseClick().omZpc
        customEvent(RDConstants.omEvtGif, properties: properties)
    }
    
    func trackGamificationClick(gameficationReport: GameficationReport) {
        var properties = Properties()
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = gameficationReport.click?.parseClick().omZn
        properties["OM.zpc"] = gameficationReport.click?.parseClick().omZpc
        customEvent(RDConstants.omEvtGif, properties: properties)
    }
}

// MARK: - Story

extension RDInstance {
    
    public func getStoryViewAsync(actionId: Int? = nil, urlDelegate: RDStoryURLDelegate? = nil, completion: @escaping StoryCompletion) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            completion(nil)
            return
        }
        
        let guid = UUID().uuidString
        let storyHomeView = RDStoryHomeView()
        let storyHomeViewController = RDStoryHomeViewController()
        storyHomeViewController.urlDelegate = urlDelegate
        storyHomeView.controller = storyHomeViewController
        rdTargetingActionInstance.rdStoryHomeViewControllers[guid] = storyHomeViewController
        rdTargetingActionInstance.rdStoryHomeViews[guid] = storyHomeView
        storyHomeView.setDelegates()
        storyHomeViewController.collectionView = storyHomeView.collectionView
        
        trackingQueue.async { [weak self, actionId, guid] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, actionId, guid] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.getStories(rdUser: self.rdUser, guid: guid, actionId: actionId, completion: { response in
                    if let error = response.error {
                        RDLogger.error(error)
                        completion(nil)
                    } else {
                        if let guid = response.guid, response.storyActions.count > 0,
                           let storyHomeViewController = self.rdTargetingActionInstance.rdStoryHomeViewControllers[guid],
                           let storyHomeView = self.rdTargetingActionInstance.rdStoryHomeViews[guid] {
                            DispatchQueue.main.async {
                                storyHomeViewController.loadStoryAction(response.storyActions.first!)
                                storyHomeView.collectionView.reloadData()
                                storyHomeView.setDelegates()
                                storyHomeViewController.collectionView = storyHomeView.collectionView
                                completion(storyHomeView)
                            }
                        } else {
                            completion(nil)
                        }
                    }
                })
            }
        }
    }
    
    public func getStoryView(actionId: Int? = nil, urlDelegate: RDStoryURLDelegate? = nil) -> RDStoryHomeView {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
            return RDStoryHomeView()
        }
        
        let guid = UUID().uuidString
        let storyHomeView = RDStoryHomeView()
        let storyHomeViewController = RDStoryHomeViewController()
        storyHomeViewController.urlDelegate = urlDelegate
        storyHomeView.controller = storyHomeViewController
        rdTargetingActionInstance.rdStoryHomeViewControllers[guid] = storyHomeViewController
        rdTargetingActionInstance.rdStoryHomeViews[guid] = storyHomeView
        storyHomeView.setDelegates()
        storyHomeViewController.collectionView = storyHomeView.collectionView
        
        trackingQueue.async { [weak self, actionId, guid] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, actionId, guid] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.getStories(rdUser: self.rdUser, guid: guid, actionId: actionId, completion: { response in
                    if let error = response.error {
                        RDLogger.error(error)
                    } else {
                        if let guid = response.guid, response.storyActions.count > 0,
                           let storyHomeViewController = self.rdTargetingActionInstance.rdStoryHomeViewControllers[guid],
                           let storyHomeView = self.rdTargetingActionInstance.rdStoryHomeViews[guid] {
                            DispatchQueue.main.async {
                                storyHomeViewController.loadStoryAction(response.storyActions.first!)
                                storyHomeView.collectionView.reloadData()
                                storyHomeView.setDelegates()
                                storyHomeViewController.collectionView = storyHomeView.collectionView
                            }
                        }
                    }
                })
            }
        }
        
        return storyHomeView
    }
}

// MARK: - RECOMMENDATION

extension RDInstance {
    public func recommend(zoneId: String, productCode: String? = nil, filters: [RDRecommendationFilter] = [], properties: Properties = [:], completion: @escaping RecommendCompletion) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
        }
        
        
        recommendationQueue.async { [weak self, zoneId, productCode, filters, properties, completion] in
            self?.networkQueue.async { [weak self, zoneId, productCode, filters, properties, completion] in
                guard let self = self else { return }
                var user = RDUser()
                self.readWriteLock.read {
                    user = self.rdUser
                }
                self.rdRecommendationInstance.recommend(zoneId: zoneId, productCode: productCode, rdUser: user, properties: properties, filters: filters) { response in
                    completion(response)
                }
            }
        }
    }
    
    public func trackRecommendationClick(qs: String) {
        
        if RDPersistence.isBlocked() {
            RDLogger.warn("Too much server load, ignoring the request!")
        }
        
        let qsArr = qs.components(separatedBy: "&")
        var properties = Properties()
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        if(qsArr.count > 1) {
            for queryItem in qsArr {
                let arrComponents = queryItem.components(separatedBy: "=")
                if arrComponents.count == 2 {
                    properties[arrComponents[0]] = arrComponents[1]
                }
            }
        } else {
            RDLogger.info("qs length is less than 2")
            return
        }
        customEvent(RDConstants.omEvtGif, properties: properties)
    }
    
}

// MARK: - GEOFENCE


extension RDInstance {

    public var locationServicesEnabledForDevice: Bool {
        return RDGeofenceState.locationServicesEnabledForDevice
    }
    
    public var locationServiceStateStatusForApplication: RDCLAuthorizationStatus {
        return RDGeofenceState.locationServiceStateStatusForApplication
    }
    
    public func sendLocationPermission() {
        rdLocationManager.sendLocationPermission(geofenceEnabled: rdProfile.geofenceEnabled)
    }
    
    public func requestLocationPermissions() {
        rdLocationManager.requestLocationPermissions()
    }
    
}

// MARK: - SUBSCRIPTION MAIL


extension RDInstance {
    public func subscribeMail(click: String, actid: String, auth: String, mail: String) {
        if click.isEmpty {
            RDLogger.info("Notification or query string is nil or empty")
            return
        }
        
        var properties = Properties()
        properties[RDConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = click.parseClick().omZn
        properties["OM.zpc"] = click.parseClick().omZpc
        customEvent(RDConstants.omEvtGif, properties: properties)
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail)
    }
    
    private func createSubsJsonRequest(actid: String, auth: String, mail: String, type: String = "subscription_email") {
        var props = Properties()
        props[RDConstants.type] = type
        props["actionid"] = actid
        props[RDConstants.authentication] = auth
        props[RDConstants.subscribedEmail] = mail
        RDRequest.sendSubsJsonRequest(properties: props)
    }
}

// MARK: - REMOTE CONFIG


extension RDInstance {
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        rdRemoteConfigInstance.applicationDidBecomeActive()
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        rdRemoteConfigInstance.applicationWillResignActive()
    }
}


// MARK: - PUSH


extension RDInstance {
    
    public func enablePushNotifications(appAlias: String, launchOptions: [UIA.LaunchOptionsKey : Any]? = nil, appGroupsKey: String? = nil, deliveredBadge: Bool? = true) {
        rdProfile.isPushNotificationEnabled = true
        rdProfile.appAlias = appAlias
        rdProfile.appGroupsKey = appGroupsKey
        if let launchOptions = launchOptions {
            self.launchOptions = launchOptions
        }
        RDPush.configure(appAlias: appAlias, launchOptions: self.launchOptions, appGroupsKey: appGroupsKey, deliveredBadge: deliveredBadge)
    }
    
    public func askForNotificationPermission(register: Bool = false) {
        RDPush.askForNotificationPermission(register: register)
    }
    
    public func askForNotificationPermissionProvisional(register: Bool = false) {
        RDPush.askForNotificationPermissionProvisional(register: register)
    }
    
    public func registerForPushNotifications() {
        RDPush.registerForPushNotifications()
    }
    
    public func setPushNotification(permission: Bool) {
        RDPush.setPushNotification(permission: permission)
    }
    
    public func setPhoneNumber(msisdn: String? = nil, permission: Bool) {
        RDPush.setPhoneNumber(msisdn: msisdn, permission: permission)
    }
    
    public func setEmail(email: String? = nil, permission: Bool) {
        RDPush.setEmail(email: email, permission: permission)
    }
    
    public func setEmail(email: String?) {
        RDPush.setEmail(email: email)
    }
    
    public func setEuroUserId(userKey: String?) {
        RDPush.setEuroUserId(userKey: userKey)
    }
    
    public func setAppVersion(appVersion: String?) {
        RDPush.setAppVersion(appVersion: appVersion)
    }
    
    public func setTwitterId(twitterId: String?) {
        RDPush.setTwitterId(twitterId: twitterId)
    }
    
    public func setAdvertisingIdentifier(adIdentifier: String?) {
        RDPush.setAdvertisingIdentifier(adIdentifier: adIdentifier)
    }
    
    public func setFacebook(facebookId: String?) {
        RDPush.setFacebook(facebookId: facebookId)
    }
    
    public func setUserProperty(key: String, value: String?) {
        RDPush.setUserProperty(key: key, value: value)
    }
    
    public func removeUserProperty(key: String) {
        RDPush.removeUserProperty(key: key)
    }
    
    public func setBadge(count: Int) {
        RDPush.setBadge(count: count)
    }
    
    public func registerToken(tokenData: Data?) {
        RDPush.registerToken(tokenData: tokenData)
    }
    
    public func handlePush(pushDictionary: [AnyHashable: Any]) {
        RDPush.handlePush(pushDictionary: pushDictionary)
    }
    
    public func sync(notification: Notification? = nil) {
        RDPush.sync(notification: notification)
    }

    public func registerEmail(email: String, permission: Bool, isCommercial: Bool = false, customDelegate: RDPushDelegate? = nil) {
        RDPush.registerEmail(email: email, permission: permission, isCommercial: isCommercial, customDelegate: customDelegate)
    }
    
    public func getPushMessages(completion: @escaping GetPushMessagesCompletion) {
        RDPush.getPushMessages(completion: completion)
    }
    func getPushMessagesWithID(completion: @escaping GetPushMessagesCompletion) {
        RDPush.getPushMessagesWithId(completion: completion)
    }
    
}



public protocol RDInappButtonDelegate: AnyObject {
    func didTapButton(_ notification: RDInAppNotification)
}
