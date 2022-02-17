//
//  RelatedDigitalInstance.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 4.05.2020.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit
import UserNotifications

protocol RelatedDigitalInstanceProtocol {
    var exVisitorId: String? { get }
    var rdUser: RelatedDigitalUser { get }
    var rdProfile: RelatedDigitalProfile { get }
    var locationServicesEnabledForDevice: Bool { get }
    var locationServiceStateStatusForApplication: RelatedDigitalCLAuthorizationStatus { get }
    var inappButtonDelegate: RelatedDigitalInappButtonDelegate? { get set }
    var loggingEnabled: Bool { get set }
    var inAppNotificationsEnabled: Bool { get set }
    func requestIDFA()
    func sendLocationPermission()
    func customEvent(_ pageName: String, properties: [String: String])
    func login(exVisitorId: String, properties: [String: String])
    func signUp(exVisitorId: String, properties: [String: String])
    func logout()
    func showNotification(_ relatedDigitalInAppNotification: RelatedDigitalInAppNotification)
    func subscribeSpinToWinMail(actid: String, auth: String, mail: String)
    func subscribeMail(click: String, actid: String, auth: String, mail: String)
    func trackSpinToWinClick(spinToWinReport: SpinToWinReport)
    func trackRecommendationClick(qs: String)
    func getStoryView(actionId: Int?, urlDelegate: RelatedDigitalStoryURLDelegate?) -> RelatedDigitalStoryHomeView
    func getStoryViewAsync(actionId: Int?, urlDelegate: RelatedDigitalStoryURLDelegate?, completion: @escaping ((_ storyHomeView: RelatedDigitalStoryHomeView?) -> Void))
    func recommend(zoneId: String, productCode: String?, filters: [RelatedDigitalRecommendationFilter], properties: [String: String],
                          completion: @escaping ((_ response: RelatedDigitalRecommendationResponse) -> Void))
    func getFavoriteAttributeActions(actionId: Int?, completion: @escaping ((_ response: RelatedDigitalFavoriteAttributeActionResponse) -> Void))
}

public class RelatedDigitalInstance: RelatedDigitalInstanceProtocol {
    
    var exVisitorId: String? { return rdUser.exVisitorId }
    var rdUser = RelatedDigitalUser()
    var rdProfile: RelatedDigitalProfile
    var rdCookie = RelatedDigitalCookie()
    var eventsQueue = Queue()
    var trackingQueue: DispatchQueue!
    var targetingActionQueue: DispatchQueue!
    var recommendationQueue: DispatchQueue!
    var networkQueue: DispatchQueue!
    let readWriteLock: RelatedDigitalReadWriteLock
    private var observers: [NSObjectProtocol]? = []

    let rdEventInstance: RelatedDigitalEvent
    let rdSendInstance: RelatedDigitalSend
    let rdTargetingActionInstance: RelatedDigitalTargetingAction
    let rdRecommendationInstance: RelatedDigitalRecommendation
    let rdRemoteConfigInstance: RelatedDigitalRemoteConfig
    
    public var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                RelatedDigitalLogger.addLogging(RelatedDigitalPrintLogging())
                RelatedDigitalLogger.enableLevels([.debug, .info, .warning, .error])
                RelatedDigitalLogger.info("Logging Enabled")
            } else {
                RelatedDigitalLogger.info("Logging Disabled")
                RelatedDigitalLogger.disableLevels([.debug, .info, .warning, .error])
            }
        }
    }
    
    public var inAppNotificationsEnabled: Bool {
        get {
            return rdProfile.inAppNotificationsEnabled
        }
        set {
            rdProfile.inAppNotificationsEnabled = newValue
            RelatedDigitalPersistence.saveRelatedDigitalProfile(rdProfile)
        }
    }
    
    public var useInsecureProtocol: Bool = false {
        didSet {
            rdProfile.useInsecureProtocol = useInsecureProtocol
            RelatedDigitalHelper.setEndpoints(dataSource: rdProfile.dataSource, useInsecureProtocol: useInsecureProtocol)
            RelatedDigitalPersistence.saveRelatedDigitalProfile(rdProfile)
        }
    }
    
    public weak var inappButtonDelegate: RelatedDigitalInappButtonDelegate?
    
    // swiftlint:disable function_body_length
    init(organizationId: String, profileId: String, dataSource: String) {
        
        rdProfile = RelatedDigitalPersistence.readRelatedDigitalProfile() ?? RelatedDigitalProfile(organizationId: organizationId, profileId: profileId, dataSource: dataSource, channel: "IOS", requestTimeoutInSeconds: 30, geofenceEnabled: false, inAppNotificationsEnabled: false, maxGeofenceCount: 20, isIDFAEnabled: false)
        rdProfile.organizationId = organizationId
        rdProfile.profileId = profileId
        rdProfile.dataSource = dataSource
 
        RelatedDigitalPersistence.saveRelatedDigitalProfile(rdProfile)
        readWriteLock = RelatedDigitalReadWriteLock(label: "RelatedDigitalInstanceLock")
        let label = "com.relateddigital.\(rdProfile.profileId)"
        trackingQueue = DispatchQueue(label: "\(label).tracking)", qos: .utility)
        recommendationQueue = DispatchQueue(label: "\(label).recommendation)", qos: .utility)
        targetingActionQueue = DispatchQueue(label: "\(label).targetingaction)", qos: .utility)
        networkQueue = DispatchQueue(label: "\(label).network)", qos: .utility)
        rdEventInstance = RelatedDigitalEvent(rdProfile: rdProfile)
        rdSendInstance = RelatedDigitalSend()
        rdTargetingActionInstance = RelatedDigitalTargetingAction(lock: readWriteLock, rdProfile: rdProfile)
        rdRecommendationInstance = RelatedDigitalRecommendation(relatedDigitalProfile: rdProfile)
        rdRemoteConfigInstance = RelatedDigitalRemoteConfig(profileId: rdProfile.profileId)
        
        
        RelatedDigitalHelper.setEndpoints(dataSource: rdProfile.dataSource)

        rdUser = unarchive()
        rdUser.sdkVersion = RelatedDigitalHelper.getSdkVersion()
        
        if let appVersion = RelatedDigitalHelper.getAppVersion() {
            rdUser.appVersion = appVersion
        }
        
        if rdUser.cookieId.isNilOrWhiteSpace {
            rdUser.cookieId = RelatedDigitalHelper.generateCookieId()
            RelatedDigitalPersistence.archiveUser(rdUser)
        }
        
        if rdProfile.isIDFAEnabled {
            RelatedDigitalHelper.getIDFA { uuid in
                if let idfa = uuid {
                    self.rdUser.identifierForAdvertising = idfa
                }
            }
        }
        
        if rdProfile.geofenceEnabled {
            startGeofencing()
        }

        rdTargetingActionInstance.inAppDelegate = self
        
        
        
        RelatedDigitalHelper.computeWebViewUserAgent { userAgentString in
            self.rdUser.userAgent = userAgentString
        }
        
        let ncd = NotificationCenter.default
        observers = []
        
        if !RelatedDigitalHelper.isiOSAppExtension() {
            observers?.append(ncd.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: nil,
                using: self.applicationDidBecomeActive(_:)))
            observers?.append(ncd.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: nil,
                using: self.applicationWillResignActive(_:)))
        }
    }
    
    convenience init?() {
        if let relatedDigitalProfile = RelatedDigitalPersistence.readRelatedDigitalProfile() {
            self.init(organizationId: relatedDigitalProfile.organizationId, profileId: relatedDigitalProfile.profileId, dataSource: relatedDigitalProfile.dataSource)
        } else {
            return nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification,
                                                  object: nil)
    }
    
    static func sharedUIApplication() -> UIApplication? {
        let shared = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue()
        guard let sharedApplication = shared as? UIApplication else {
            return nil
        }
        return sharedApplication
    }
}

// MARK: - IDFA

extension RelatedDigitalInstance {
    
    public func requestIDFA() {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        RelatedDigitalHelper.getIDFA { uuid in
            if let idfa = uuid {
                self.rdUser.identifierForAdvertising = idfa
                self.customEvent(RelatedDigitalConstants.omEvtGif, properties: [String: String]())
            }
        }
    }
    
}

// MARK: - EVENT

extension RelatedDigitalInstance {
    
    private func checkPushPermission() {
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus {
            case .authorized:
                RelatedDigitalConstants.pushPermitStatus = "granted"
            case .denied:
                RelatedDigitalConstants.pushPermitStatus = "denied"
            case .notDetermined:
                RelatedDigitalConstants.pushPermitStatus = "denied"
            case .provisional:
                RelatedDigitalConstants.pushPermitStatus = "default"
            case .ephemeral:
                RelatedDigitalConstants.pushPermitStatus = "denied"
            @unknown default:
                RelatedDigitalConstants.pushPermitStatus = "denied"
            }
        })
    }
    
    private func sideBarTest(imageData:UIImage) {
        
        let model = SideBarModel()
        model.dataImage = imageData
        let sideBar = RelatedDigitalSideBarViewController(model:model)
        sideBar.show(animated: true)
        
    }
    
    public func customEvent(_ pageName: String, properties: [String: String]) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if pageName.isEmptyOrWhitespace {
            RelatedDigitalLogger.error("customEvent can not be called with empty page name.")
            return
        }
        
        checkPushPermission()
        
        trackingQueue.async { [weak self, pageName, properties] in
            guard let self = self else { return }
            var eQueue = Queue()
            var user = RelatedDigitalUser()
            var chan = ""
            self.readWriteLock.read {
                eQueue = self.eventsQueue
                user = self.rdUser
                chan = self.rdProfile.channel
            }
            let result = self.rdEventInstance.customEvent(pageName: pageName,
                                                                      properties: properties,
                                                                      eventsQueue: eQueue,
                                                                      rdUser: user,
                                                                      channel: chan)
            self.readWriteLock.write {
                self.eventsQueue = result.eventsQueque
                self.rdUser = result.rdUser
                self.rdProfile.channel = result.channel
            }
            self.readWriteLock.read {
                RelatedDigitalPersistence.archiveUser(self.rdUser)
                if result.clearUserParameters {
                    RelatedDigitalPersistence.clearTargetParameters()
                }
            }
            if let event = self.eventsQueue.last {
                RelatedDigitalPersistence.saveTargetParameters(event)
                if RelatedDigitalBasePath.endpoints[.action] != nil,
                   self.rdProfile.inAppNotificationsEnabled,
                   pageName != RelatedDigitalConstants.omEvtGif {
                    self.checkInAppNotification(properties: event)
                    self.checkTargetingActions(properties: event)
                }
            }
            self.send()
        }
    }
    
    public func sendCampaignParameters(properties: [String: String]) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        trackingQueue.async { [weak self, properties] in
            guard let strongSelf = self else { return }
            var eQueue = Queue()
            var user = RelatedDigitalUser()
            var chan = ""
            strongSelf.readWriteLock.read {
                eQueue = strongSelf.eventsQueue
                user = strongSelf.rdUser
                chan = strongSelf.rdProfile.channel
            }
            let result = strongSelf.rdEventInstance.customEvent(properties: properties,
                                                                            eventsQueue: eQueue,
                                                                            rdUser: user,
                                                                            channel: chan)
            strongSelf.readWriteLock.write {
                strongSelf.eventsQueue = result.eventsQueque
                strongSelf.rdUser = result.rdUser
                strongSelf.rdProfile.channel = result.channel
            }
            strongSelf.readWriteLock.read {
                RelatedDigitalPersistence.archiveUser(strongSelf.rdUser)
                if result.clearUserParameters {
                    RelatedDigitalPersistence.clearTargetParameters()
                }
            }
            if let event = strongSelf.eventsQueue.last {
                RelatedDigitalPersistence.saveTargetParameters(event)
            }
            strongSelf.send()
        }
    }
    
    public func login(exVisitorId: String, properties: [String: String] = [String: String]()) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if exVisitorId.isEmptyOrWhitespace {
            RelatedDigitalLogger.error("login can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[RelatedDigitalConstants.exvisitorIdKey] = exVisitorId
        props["Login"] = exVisitorId
        props["OM.b_login"] = "Login"
        customEvent("LoginPage", properties: props)
    }
    
    public func signUp(exVisitorId: String, properties: [String: String] = [String: String]()) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return
        }
        
        if exVisitorId.isEmptyOrWhitespace {
            RelatedDigitalLogger.error("signUp can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[RelatedDigitalConstants.exvisitorIdKey] = exVisitorId
        props["SignUp"] = exVisitorId
        props["OM.b_sgnp"] = "SignUp"
        customEvent("SignUpPage", properties: props)
    }
    
    public func logout() {
        RelatedDigitalPersistence.clearUserDefaults()
        rdUser.cookieId = nil
        rdUser.exVisitorId = nil
        rdUser.cookieId = RelatedDigitalHelper.generateCookieId()
        RelatedDigitalPersistence.archiveUser(rdUser)
    }
    
}

// MARK: - PERSISTENCE

extension RelatedDigitalInstance {

    // TO_DO: kontrol et sıra doğru mu? gelen değerler null ise set'lemeli miyim?
    private func unarchive() -> RelatedDigitalUser {
        return RelatedDigitalPersistence.unarchiveUser()
    }
}

// MARK: - SEND

extension RelatedDigitalInstance {
    private func send() {
        trackingQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var eQueue = Queue()
                var user = RelatedDigitalUser()
                var vCookie = RelatedDigitalCookie()
                self.readWriteLock.read {
                    eQueue = self.eventsQueue
                    user = self.rdUser
                    vCookie = self.rdCookie
                }
                self.readWriteLock.write {
                    self.eventsQueue.removeAll()
                }
                let cookie = self.rdSendInstance.sendEventsQueue(eQueue,
                                                                             rdUser: user,
                                                                             relatedDigitalCookie: vCookie,
                                                                             timeoutInterval: self.rdProfile.requestTimeoutInterval)
                self.readWriteLock.write {
                    self.rdCookie = cookie
                }
            }
        }
    }
}

// MARK: - TARGETING ACTIONS

// MARK: - Favorite Attribute Actions

extension RelatedDigitalInstance {
    public func getFavoriteAttributeActions(actionId: Int? = nil,
                                            completion: @escaping ((_ response: RelatedDigitalFavoriteAttributeActionResponse)
                                                                   -> Void)) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            completion(RelatedDigitalFavoriteAttributeActionResponse(favorites: [RelatedDigitalFavoriteAttribute: [String]](), error: .noData))
            return
        }
        
        targetingActionQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var user = RelatedDigitalUser()
                self.readWriteLock.read {
                    user = self.rdUser
                }
                self.rdTargetingActionInstance.getFavorites(rdUser: user,
                                                                        actionId: actionId,
                                                                        completion: completion)
            }
        }
    }
}

// MARK: - InAppNotification

extension RelatedDigitalInstance: RelatedDigitalInAppNotificationsDelegate {
    // This method added for test purposes
    public func showNotification(_ relatedDigitalInAppNotification: RelatedDigitalInAppNotification) {
        rdTargetingActionInstance.notificationsInstance.showNotification(relatedDigitalInAppNotification)
    }
    
    public func showTargetingAction(_ model: TargetingActionViewModel) {
        rdTargetingActionInstance.notificationsInstance.showTargetingAction(model)
    }
    
    func checkInAppNotification(properties: [String: String]) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.checkInAppNotification(properties: properties,
                                                                                  rdUser: self.rdUser,
                                                                                  completion: { relatedDigitalInAppNotification in
                    if let notification = relatedDigitalInAppNotification {
                        self.rdTargetingActionInstance.notificationsInstance.inappButtonDelegate = self.inappButtonDelegate
                        self.rdTargetingActionInstance.notificationsInstance.showNotification(notification)
                    }
                })
            }
        }
    }
    
    func notificationDidShow(_ notification: RelatedDigitalInAppNotification) {
        rdUser.visitData = notification.visitData
        rdUser.visitorData = notification.visitorData
        RelatedDigitalPersistence.archiveUser(rdUser)
    }
    
    func trackNotification(_ notification: RelatedDigitalInAppNotification, event: String, properties: [String: String]) {
        if notification.queryString == nil || notification.queryString == "" {
            RelatedDigitalLogger.info("Notification or query string is nil or empty")
            return
        }
        let queryString = notification.queryString
        let qsArr = queryString!.components(separatedBy: "&")
        var properties = properties
        properties[RelatedDigitalConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = qsArr[0].components(separatedBy: "=")[1]
        properties["OM.zpc"] = qsArr[1].components(separatedBy: "=")[1]
        customEvent(RelatedDigitalConstants.omEvtGif, properties: properties)
    }
    
    // İleride inapp de s.visilabs.net/mobile üzerinden geldiğinde sadece bu metod kullanılacak
    // checkInAppNotification metodu kaldırılacak.
    func checkTargetingActions(properties: [String: String]) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.checkTargetingActions(properties: properties, relatedDigitalUser: self.rdUser, completion: { model in
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
    
    func trackSpinToWinClick(spinToWinReport: SpinToWinReport) {
        var properties = [String: String]()
        properties[RelatedDigitalConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = spinToWinReport.click.parseClick().omZn
        properties["OM.zpc"] = spinToWinReport.click.parseClick().omZpc
        customEvent(RelatedDigitalConstants.omEvtGif, properties: properties)
    }
}

// MARK: - Story

extension RelatedDigitalInstance {
    
    public func getStoryViewAsync(actionId: Int? = nil, urlDelegate: RelatedDigitalStoryURLDelegate? = nil
                                  , completion: @escaping ((_ storyHomeView: RelatedDigitalStoryHomeView?) -> Void)) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            completion(nil)
            return
        }
        
        let guid = UUID().uuidString
        let storyHomeView = RelatedDigitalStoryHomeView()
        let storyHomeViewController = RelatedDigitalStoryHomeViewController()
        storyHomeViewController.urlDelegate = urlDelegate
        storyHomeView.controller = storyHomeViewController
        rdTargetingActionInstance.relatedDigitalStoryHomeViewControllers[guid] = storyHomeViewController
        rdTargetingActionInstance.relatedDigitalStoryHomeViews[guid] = storyHomeView
        storyHomeView.setDelegates()
        storyHomeViewController.collectionView = storyHomeView.collectionView
        
        trackingQueue.async { [weak self, actionId, guid] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, actionId, guid] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.getStories(rdUser: self.rdUser,
                                                                      guid: guid,
                                                                      actionId: actionId,
                                                                      completion: { response in
                    if let error = response.error {
                        RelatedDigitalLogger.error(error)
                        completion(nil)
                    } else {
                        if let guid = response.guid, response.storyActions.count > 0,
                           let storyHomeViewController = self.rdTargetingActionInstance.relatedDigitalStoryHomeViewControllers[guid],
                           let storyHomeView = self.rdTargetingActionInstance.relatedDigitalStoryHomeViews[guid] {
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
    
    public func getStoryView(actionId: Int? = nil, urlDelegate: RelatedDigitalStoryURLDelegate? = nil) -> RelatedDigitalStoryHomeView {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
            return RelatedDigitalStoryHomeView()
        }
        
        let guid = UUID().uuidString
        let storyHomeView = RelatedDigitalStoryHomeView()
        let storyHomeViewController = RelatedDigitalStoryHomeViewController()
        storyHomeViewController.urlDelegate = urlDelegate
        storyHomeView.controller = storyHomeViewController
        rdTargetingActionInstance.relatedDigitalStoryHomeViewControllers[guid] = storyHomeViewController
        rdTargetingActionInstance.relatedDigitalStoryHomeViews[guid] = storyHomeView
        storyHomeView.setDelegates()
        storyHomeViewController.collectionView = storyHomeView.collectionView
        
        trackingQueue.async { [weak self, actionId, guid] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, actionId, guid] in
                guard let self = self else { return }
                self.rdTargetingActionInstance.getStories(rdUser: self.rdUser,
                                                                      guid: guid,
                                                                      actionId: actionId,
                                                                      completion: { response in
                    if let error = response.error {
                        RelatedDigitalLogger.error(error)
                    } else {
                        if let guid = response.guid, response.storyActions.count > 0,
                           let storyHomeViewController = self.rdTargetingActionInstance.relatedDigitalStoryHomeViewControllers[guid],
                           let storyHomeView = self.rdTargetingActionInstance.relatedDigitalStoryHomeViews[guid] {
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

extension RelatedDigitalInstance {
    public func recommend(zoneId: String,
                          productCode: String? = nil,
                          filters: [RelatedDigitalRecommendationFilter] = [],
                          properties: [String: String] = [:],
                          completion: @escaping ((_ response: RelatedDigitalRecommendationResponse) -> Void)) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
        }
        
        
        recommendationQueue.async { [weak self, zoneId, productCode, filters, properties, completion] in
            self?.networkQueue.async { [weak self, zoneId, productCode, filters, properties, completion] in
                guard let self = self else { return }
                var user = RelatedDigitalUser()
                var channel = "IOS"
                self.readWriteLock.read {
                    user = self.rdUser
                    channel = self.rdProfile.channel
                }
                self.rdRecommendationInstance.recommend(zoneId: zoneId,
                                                                    productCode: productCode,
                                                                    relatedDigitalUser: user,
                                                                    channel: channel,
                                                                    properties: properties,
                                                                    filters: filters) { response in
                    completion(response)
                }
            }
        }
    }
    
    public func trackRecommendationClick(qs: String) {
        
        if RelatedDigitalPersistence.isBlocked() {
            RelatedDigitalLogger.warn("Too much server load, ignoring the request!")
        }
        
        let qsArr = qs.components(separatedBy: "&")
        var properties = [String: String]()
        properties[RelatedDigitalConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        if(qsArr.count > 1) {
            for queryItem in qsArr {
                let arrComponents = queryItem.components(separatedBy: "=")
                if arrComponents.count == 2 {
                    properties[arrComponents[0]] = arrComponents[1]
                }
            }
        } else {
            RelatedDigitalLogger.info("qs length is less than 2")
            return
        }
        customEvent(RelatedDigitalConstants.omEvtGif, properties: properties)
    }
    
}

// MARK: - GEOFENCE

extension RelatedDigitalInstance {
    private func startGeofencing() {
        RelatedDigitalGeofence.sharedManager?.startGeofencing()
    }
    
    public var locationServicesEnabledForDevice: Bool {
        return RelatedDigitalGeofence.sharedManager?.locationServicesEnabledForDevice ?? false
    }
    
    public var locationServiceStateStatusForApplication: RelatedDigitalCLAuthorizationStatus {
        return RelatedDigitalGeofence.sharedManager?.locationServiceStateStatusForApplication ?? .none
    }
    
    public func sendLocationPermission() {
        RelatedDigitalLocationManager.sharedManager.sendLocationPermission(geofenceEnabled: rdProfile.geofenceEnabled)
    }
    
    // swiftlint:disable file_length
}

// MARK: - SUBSCRIPTION MAIL

extension RelatedDigitalInstance {
    public func subscribeMail(click: String, actid: String, auth: String, mail: String) {
        if click.isEmpty {
            RelatedDigitalLogger.info("Notification or query string is nil or empty")
            return
        }
        
        var properties = [String: String]()
        properties[RelatedDigitalConstants.domainkey] = "\(rdProfile.dataSource)_IOS"
        properties["OM.zn"] = click.parseClick().omZn
        properties["OM.zpc"] = click.parseClick().omZpc
        customEvent(RelatedDigitalConstants.omEvtGif, properties: properties)
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail)
    }
    
    private func createSubsJsonRequest(actid: String, auth: String, mail: String, type: String = "subscription_email") {
        var props = [String: String]()
        props[RelatedDigitalConstants.type] = type
        props["actionid"] = actid
        props[RelatedDigitalConstants.authentication] = auth
        props[RelatedDigitalConstants.subscribedEmail] = mail
        RelatedDigitalRequest.sendSubsJsonRequest(properties: props)
    }
}

// MARK: -REMOTE CONFIG


extension RelatedDigitalInstance {
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        rdRemoteConfigInstance.applicationDidBecomeActive()
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        rdRemoteConfigInstance.applicationWillResignActive()
    }
}



public protocol RelatedDigitalInappButtonDelegate: AnyObject {
    func didTapButton(_ notification: RelatedDigitalInAppNotification)
}
