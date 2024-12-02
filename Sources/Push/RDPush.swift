//
//  RDPush.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation
import UIKit
import UserNotifications

public protocol RDPushDelegate: AnyObject {
    func didRegisterSuccessfully()
    func didFailRegister(error: PushAPIError)
}

public class RDPush {
    private static var sharedInstance: RDPush?
    private let readWriteLock: RDReadWriteLock
    internal var pushAPI: PushAPIProtocol?
    private var observers: [NSObjectProtocol]?

    static var emReadHandler: PushReadHandler?
    static var emDeliverHandler: PushDeliverHandler?
    static var emSubscriptionHandler: PushSubscriptionHandler?

    private var pushPermitDidCall: Bool = false
    weak var delegate: RDPushDelegate?
    internal var subscription: PushSubscriptionRequest
    internal var graylog: PushGraylogRequest
    private static var previousSubscription: PushSubscriptionRequest?
    private var previousRegisterEmailSubscription: PushSubscriptionRequest?
    internal var userAgent: String?
    static var deliveredBadgeCount: Bool?

    var networkQueue: DispatchQueue!

    private init(appKey: String, launchOptions: [UIA.LaunchOptionsKey: Any]?) {
        RDLogger.info("INITCALL \(appKey)")
        networkQueue = DispatchQueue(label: "com.Push.\(appKey).network)", qos: .utility)
        readWriteLock = RDReadWriteLock(label: "PushLock")
        if let lastSubscriptionData = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.registerKey) as? Data,
           let lastSubscription = try? JSONDecoder().decode(PushSubscriptionRequest.self, from: lastSubscriptionData) {
            subscription = lastSubscription
        } else {
            subscription = PushSubscriptionRequest()
        }
        subscription.setDeviceParameters()
        subscription.appKey = appKey
        subscription.token = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.tokenKey) as? String

        graylog = PushGraylogRequest()
        fillGraylogModel()

        let ncd = NC.default
        observers = []
        observers?.append(ncd.addObserver(forName: UIA.willResignActiveNotification, object: nil, queue: nil, using: RDPush.sync))
        observers?.append(ncd.addObserver(forName: UIA.willTerminateNotification, object: nil, queue: nil, using: RDPush.sync))
        observers?.append(ncd.addObserver(forName: UIA.willEnterForegroundNotification, object: nil, queue: nil, using: RDPush.sync))
        observers?.append(ncd.addObserver(forName: UIA.didBecomeActiveNotification, object: nil, queue: nil, using: RDPush.sync))

        if let userAgent = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.userAgent) as? String {
            self.userAgent = userAgent
        } else {
            PushTools.computeWebViewUserAgent { str in
                self.userAgent = str
                PushUserDefaultsUtils.saveUserDefaults(key: PushKey.userAgent, value: str as AnyObject)
            }
        }
    }

    deinit {
        NC.default.removeObserver(self, name: UIA.willResignActiveNotification, object: nil)
        NC.default.removeObserver(self, name: UIA.willTerminateNotification, object: nil)
        NC.default.removeObserver(self, name: UIA.willEnterForegroundNotification, object: nil)
        NC.default.removeObserver(self, name: UIA.didBecomeActiveNotification, object: nil)
    }

    private static func getShared() -> RDPush? {
        guard let shared = RDPush.shared else {
            RDLogger.warn(PushKey.appAliasNotProvidedMessage)
            return nil
        }
        return shared
    }

    public static var shared: RDPush? {
        get {
            guard sharedInstance?.subscription.appKey != nil,
                  sharedInstance?.subscription.appKey != "" else {
                if let subscriptionData = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.registerKey) as? Data {
                    guard let subscriptionRequest = try? JSONDecoder().decode(PushSubscriptionRequest.self, from: subscriptionData),
                          let appKey = subscriptionRequest.appKey else {
                        RDLogger.warn(PushKey.appAliasNotProvidedMessage)
                        return nil
                    }
                    RDPush.configure(appAlias: appKey, launchOptions: nil)
                    return sharedInstance
                }
                RDLogger.warn(PushKey.appAliasNotProvidedMessage)
                return nil
            }
            return sharedInstance
        }
        set {
            sharedInstance = newValue
        }
    }

    // MARK: Lifecycle

    public class func configure(appAlias: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil, appGroupsKey: String? = nil, deliveredBadge: Bool? = true) {
        if let appGroupName = PushTools.getAppGroupName(appGroupName: appGroupsKey) {
            PushUserDefaultsUtils.setAppGroupsUserDefaults(appGroupName: appGroupName)
            RDLogger.info("App Group Key : \(appGroupName)")
        }

        RDPush.shared = RDPush(appKey: appAlias, launchOptions: launchOptions)
        RDPush.shared?.pushAPI = PushAPI()
        RDPush.deliveredBadgeCount = deliveredBadge

        if let subscriptionHandler = RDPush.emSubscriptionHandler {
            subscriptionHandler.push = RDPush.shared!
        } else {
            RDPush.emSubscriptionHandler = PushSubscriptionHandler(push: RDPush.shared!)
        }

        if let readHandler = RDPush.emReadHandler {
            readHandler.push = RDPush.shared!
        } else {
            RDPush.emReadHandler = PushReadHandler(push: RDPush.shared!)
        }

        if let deliverHandler = RDPush.emDeliverHandler {
            deliverHandler.push = RDPush.shared!
        } else {
            RDPush.emDeliverHandler = PushDeliverHandler(push: RDPush.shared!)
        }

        if let userInfo = launchOptions?[UIA.LaunchOptionsKey.remoteNotification] as? [String: Any] {
            RDPush.handlePush(pushDictionary: userInfo)
        }
    }

    /// Request to user for authorization for push notification
    /// - Parameter register: also register for deviceToken. _default : false_
    public static func askForNotificationPermission(register: Bool = false) {
        let center = UNUNC.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                RDLogger.info("Notification permission granted")
                if register {
                    RDPush.registerForPushNotifications()
                }
            } else {
                RDLogger.error("An error occurred while notification permission: \(error.debugDescription)")
            }
        }
    }

    public static func askForNotificationPermissionProvisional(register: Bool = false) {
        if #available(iOS 12.0, *) {
            let center = UNUNC.current()
            center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
                if granted {
                    RDLogger.info("Notification permission granted")
                    if register {
                        RDPush.registerForPushNotifications()
                    }
                } else {
                    RDLogger.error("An error occurred while notification permission: \(error.debugDescription)")
                }
            }
        } else {
            RDPush.askForNotificationPermission(register: register)
        }
    }

    public static func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIA.shared.registerForRemoteNotifications()
        }
    }
}

public protocol PushAction {
    func actionButtonClicked(identifier: String, url: String)
}

extension RDPush {
    // MARK: Request Builders

    public static func setPushNotification(permission: Bool) {
        if permission {
            setUserProperty(key: PushProperties.CodingKeys.pushPermit.rawValue, value: PushProperties.PermissionKeys.yes.rawValue)
            registerForPushNotifications()
        } else {
            setUserProperty(key: PushProperties.CodingKeys.pushPermit.rawValue, value: PushProperties.PermissionKeys.not.rawValue)
        }
        shared?.pushPermitDidCall = true
        sync()
    }

    public static func setPhoneNumber(msisdn: String? = nil, permission: Bool) {
        let per = permission ? PushProperties.PermissionKeys.yes.rawValue : PushProperties.PermissionKeys.not.rawValue
        setUserProperty(key: PushProperties.CodingKeys.gsmPermit.rawValue, value: per)
        if PushTools.validatePhone(phone: msisdn), permission {
            setUserProperty(key: PushProperties.CodingKeys.msisdn.rawValue, value: msisdn)
        }
    }

    public static func setEmail(email: String? = nil, permission: Bool) {
        let per = permission ? PushProperties.PermissionKeys.yes.rawValue : PushProperties.PermissionKeys.not.rawValue
        setUserProperty(key: PushProperties.CodingKeys.emailPermit.rawValue, value: per)
        if PushTools.validateEmail(email: email), permission {
            setUserProperty(key: PushProperties.CodingKeys.email.rawValue, value: email)
        }
    }

    public static func setEmail(email: String?) {
        if PushTools.validateEmail(email: email) {
            setUserProperty(key: PushProperties.CodingKeys.email.rawValue, value: email)
        }
    }

    public static func setEuroUserId(userKey: String?) {
        if let userKey = userKey {
            setUserProperty(key: PushProperties.CodingKeys.keyID.rawValue, value: userKey)
        }
    }

    public static func setAnonymous(permission: Bool) {
        if permission {
            setUserProperty(key: PushProperties.CodingKeys.SetAnonymous.rawValue, value: "true")
        } else {
            setUserProperty(key: PushProperties.CodingKeys.SetAnonymous.rawValue, value: "false")
        }
        sync()
    }

    public static func setAppVersion(appVersion: String?) {
        guard let shared = getShared() else { return }
        if let appVersion = appVersion {
            shared.readWriteLock.write {
                shared.subscription.appVersion = appVersion
            }
        }
        saveSubscription()
    }

    public static func setTwitterId(twitterId: String?) {
        if let twitterId = twitterId {
            setUserProperty(key: PushProperties.CodingKeys.twitter.rawValue, value: twitterId)
        }
    }

    public static func setAdvertisingIdentifier(adIdentifier: String?) {
        guard let shared = getShared() else { return }
        if let adIdentifier = adIdentifier {
            shared.readWriteLock.write {
                shared.subscription.advertisingIdentifier = adIdentifier
            }
        }
        saveSubscription()
    }

    public static func setFacebook(facebookId: String?) {
        if let facebookId = facebookId {
            setUserProperty(key: PushProperties.CodingKeys.facebook.rawValue, value: facebookId)
        }
    }

    public static func setUserProperty(key: String, value: String?) {
        if let shared = getShared(), let value = value {
            shared.readWriteLock.write {
                shared.subscription.extra?[key] = value
            }
            saveSubscription()
        }
    }

    public static func removeUserProperty(key: String) {
        if let shared = getShared() {
            shared.readWriteLock.write {
                shared.subscription.extra?[key] = nil
            }
            saveSubscription()
        }
    }

    public static func logout() {
        if let shared = getShared() {
            shared.readWriteLock.write {
                shared.subscription.token = nil
                shared.subscription.extra = Properties()
            }
            PushUserDefaultsUtils.removeUserDefaults(userKey: PushKey.tokenKey) // TODO: burada niye token var, android'de token silme yok
            // PushTools.removeUserDefaults(userKey: PushKey.registerKey) // TODO: bunu kaldırdım. zaten token yoksa request atılmıyor.
            saveSubscription()
        }
    }

    private static func saveSubscription() {
        if let shared = RDPush.getShared() {
            var subs: PushSubscriptionRequest?
            shared.readWriteLock.read {
                subs = shared.subscription
                shared.fillGraylogModel()
            }
            if let subs = subs, let subscriptionData = try? JSONEncoder().encode(subs) {
                PushUserDefaultsUtils.saveUserDefaults(key: PushKey.registerKey, value: subscriptionData as AnyObject)
            }
        }
    }

    /// RelatedDigital SDK manage badge count by itself. If you want to use your custom badge count use this function.
    /// To get back this configuration set count to "-1".
    /// - Parameter count: badge count ( "-1" to give control to SDK )
    public static func setBadge(count: Int) {
        PushUserDefaultsUtils.userDefaults?.set(count == -1 ? false : true, forKey: PushKey.isBadgeCustom)
        UIA.shared.applicationIconBadgeNumber = count == -1 ? 0 : count
    }

    // MARK: API Methods

    /** :
     Registers device token to RelatedDigital services.
     To get deviceToken data use  `didRegisterForRemoteNotificationsWithDeviceToken` delegate function.
     For more information visit [RelatedDigital Documentation](https://github.com/relateddigital/relateddigital-ios)
     - Parameter tokenData: delegate deviceToken data

     func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken
     deviceToken: Data) {
     Push.shared?.registerToken(tokenData: deviceToken)
     }
     */
    public static func registerToken(tokenData: Data?) {
        guard let shared = getShared() else { return }
        guard let tokenData = tokenData else {
            RDLogger.error("Token data cannot be nil")
            return
        }
        let tokenString = tokenData.reduce("", { $0 + String(format: "%02X", $1) })
        RDLogger.info("Your token is \(tokenString)")
        shared.readWriteLock.write {
            shared.subscription.token = tokenString
        }
        RDPush.sync()
    }

    public static func handlePushWithActionButtons(response: UNNotificationResponse, type: Any) {
        var actionButtonDelegate: PushAction?
        actionButtonDelegate = type as? PushAction

        let pushDictionary = response.notification.request.content.userInfo

        if let jsonData = try? JSONSerialization.data(withJSONObject: pushDictionary, options: .prettyPrinted),
           let message = try? JSONDecoder().decode(RDPushMessage.self, from: jsonData) {
            if response.actionIdentifier == "action_0" {
                actionButtonDelegate?.actionButtonClicked(identifier: "action_0", url: message.actions?.first?.Url ?? "")
            } else if response.actionIdentifier == "action_1" {
                actionButtonDelegate?.actionButtonClicked(identifier: "action_1", url: message.actions?.last?.Url ?? "")
            }
        }
    }

    static func openLink(urlStr: String) {
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    /// Report RelatedDigital services that a push notification successfully read
    /// - Parameter pushDictionary: push notification data that comes from APNS
    public static func handlePush(pushDictionary: [AnyHashable: Any]) {
        var properties = [String: String]()
        guard let shared = getShared() else { return }
        guard pushDictionary["pushId"] != nil else {
            return
        }
        RDLogger.info("handlePush: \(pushDictionary)")
        if let jsonData = try? JSONSerialization.data(withJSONObject: pushDictionary, options: .prettyPrinted),
           let message = try? JSONDecoder().decode(RDPushMessage.self, from: jsonData) {
            shared.networkQueue.async {
                PushUserDefaultsUtils.updatePayload(pushId: message.pushId)
                RDLogger.info("handlePush message: \(message.encode ?? "")")
                RDPush.emReadHandler?.reportRead(message: message)
                if let utm_source = message.utm_source {
                    properties["utm_source"] = utm_source
                }
                if let utm_medium = message.utm_medium {
                    properties["utm_medium"] = utm_medium
                }
                if let utm_campaign = message.utm_campaign {
                    properties["utm_campaign"] = utm_campaign
                }
                if let utm_content = message.utm_content {
                    properties["utm_content"] = utm_content
                }
                if let utm_term = message.utm_term {
                    properties["utm_term"] = utm_term
                }
                
                let currentDate = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
                let formattedDate = formatter.string(from: currentDate)
                properties["isPushUser"] = "true"
                properties["pushTime"] = formattedDate
                
                if !properties.isEmpty {
                    RelatedDigital.sendCampaignParameters(properties: properties)
                }
            }
        } else {
            RDLogger.error("pushDictionary parse failed")
            RDPush.sendGraylogMessage(logLevel: PushKey.graylogLogLevelError, logMessage: "pushDictionary parse failed")
        }
    }
}

extension RDPush {
    // MARK: Sync

    /// Synchronize user data with RelatedDigital servers
    /// - Parameter notification: no need for direct call
    public static func sync(notification: Notification? = nil) {
        guard let shared = getShared() else { return }
        if !shared.pushPermitDidCall {
            let center = UNUNC.current()
            center.getNotificationSettings { settings in
                if settings.authorizationStatus == .denied {
                    setUserProperty(key: PushProperties.CodingKeys.pushPermit.rawValue, value: PushProperties.PermissionKeys.not.rawValue)
                    var subs: PushSubscriptionRequest!
                    shared.readWriteLock.read {
                        subs = shared.subscription
                    }
                    shared.networkQueue.async {
                        RDPush.emSubscriptionHandler?.reportSubscription(subscriptionRequest: subs)
                    }
                } else {
                    setUserProperty(key: PushProperties.CodingKeys.pushPermit.rawValue, value: PushProperties.PermissionKeys.yes.rawValue)
                }
            }
        }

        var subs: PushSubscriptionRequest!
        var previousSubs: PushSubscriptionRequest?

        shared.readWriteLock.read {
            subs = shared.subscription
        }

        // Clear badge
        if !(subs.isBadgeCustom ?? false) {
            PushUserDefaultsUtils.removeUserDefaults(userKey: PushKey.badgeCount)

            if !PushTools.isiOSAppExtension() {
                if deliveredBadgeCount! {
                    UNUNC.current().getDeliveredNotifications(completionHandler: { notifications in
                        DispatchQueue.main.async {
                            UIA.shared.applicationIconBadgeNumber = notifications.count
                        }
                    })
                }
            }
        }
        // check whether the user have an unreported message
        shared.networkQueue.async {
            RDPush.emReadHandler?.checkUserUnreportedMessages()
        }

        shared.readWriteLock.read {
            subs = shared.subscription
            previousSubs = RDPush.previousSubscription
        }

        var shouldSendSubscription = false

        if subs.isValid() {
            shared.readWriteLock.write {
                if previousSubs == nil || subs != previousSubs {
                    RDPush.previousSubscription = subs
                    shouldSendSubscription = true
                }
            }

            if !shouldSendSubscription {
                RDLogger.warn("Subscription request not ready : \(String(describing: subs))")
                return
            }

            saveSubscription()
            shared.readWriteLock.read {
                subs = shared.subscription
            }
            PushUserDefaultsUtils.saveUserDefaults(key: PushKey.tokenKey, value: subs.token as AnyObject)
            RDLogger.info("Current subscription \(subs.encoded)")
        } else {
            RDLogger.warn("Subscription request is not valid : \(String(describing: subs))")
            return
        }

        shared.readWriteLock.read {
            subs = shared.subscription
        }

        shared.networkQueue.async {
            emSubscriptionHandler?.reportSubscription(subscriptionRequest: subs)
        }
    }

    /// Returns all the information that set before
    public static func checkConfiguration() -> PushConfiguration {
        guard let shared = getShared() else { return PushConfiguration() }
        var registerRequest: PushSubscriptionRequest!
        shared.readWriteLock.read {
            registerRequest = shared.subscription
        }
        var properties: PushProperties?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: registerRequest.extra ?? [:], options: [])
            properties = try JSONDecoder().decode(PushProperties.self, from: jsonData)
        } catch {
        }
        return PushConfiguration(userProperties: registerRequest.extra,
                                 properties: properties,
                                 firstTime: registerRequest.firstTime,
                                 osVersion: registerRequest.osVersion,
                                 deviceType: registerRequest.deviceType,
                                 osName: registerRequest.osName,
                                 deviceName: registerRequest.deviceName,
                                 token: registerRequest.token,
                                 local: registerRequest.local,
                                 identifierForVendor: registerRequest.identifierForVendor,
                                 appKey: registerRequest.appKey,
                                 appVersion: registerRequest.appVersion,
                                 advertisingIdentifier: registerRequest.advertisingIdentifier,
                                 sdkVersion: registerRequest.sdkVersion,
                                 sdkType: registerRequest.sdkType,
                                 carrier: registerRequest.carrier)
    }

    public static func getIdentifierForVendorString() -> String {
        return PushTools.getIdentifierForVendorString()
    }

    public static func getPushMessages(completion: @escaping ((_ payloads: [RDPushMessage]) -> Void)) {
        completion(PushUserDefaultsUtils.getRecentPayloads())
    }

    public static func getPushMessagesWithId(completion: @escaping ((_ payloads: [RDPushMessage]) -> Void)) {
        completion(PushUserDefaultsUtils.getRecentPayloadsWithId())
    }

    public static func deletePayloadWithId(pushId: String? = nil, completion: @escaping ((_ completed: Bool) -> Void)) {
            if let pushId = pushId {
                PushUserDefaultsUtils.deletePayloadWithId(pushId: pushId) { success in
                    completion(success)
                }
            } else {
                PushUserDefaultsUtils.deletePayloadWithId { success in
                    completion(success)
                }
            }
            
        }
        
    public static func deletePayload(pushId: String? = nil, completion: @escaping ((_ completed: Bool) -> Void)) {
        if let pushId = pushId {
            PushUserDefaultsUtils.deletePayload(pushId: pushId) { success in
                    completion(success)
                }
            } else {
                PushUserDefaultsUtils.deletePayload { success in
                    completion(success)
                }
            }
        }

    public static func getToken(completion: @escaping ((_ token: String) -> Void)) {
        let token = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.tokenKey) as? String
            ?? (RDPush.sharedInstance?.subscription.token ?? "")
        completion(token)
    }

    public static func readPushMessagesWithId(pushId: String? = nil, completion: @escaping ((_ success: Bool) -> Void)) {
        if let pushId = pushId {
            PushUserDefaultsUtils.readPushMessagesWithId(pushId: pushId) { success in
                completion(success)
            }
        } else {
            PushUserDefaultsUtils.readPushMessagesWithId { success in
                completion(success)
            }
        }
    }
    
    public static func readPushMessages(pushId: String? = nil, completion: @escaping ((_ success: Bool) -> Void)) {
        if let pushId = pushId {
            PushUserDefaultsUtils.readPushMessages(pushId: pushId) { success in
                completion(success)
            }
        } else {
            PushUserDefaultsUtils.readPushMessages { success in
                completion(success)
            }
        }
    }
}

extension RDPush {
    // MARK: - Notification Extension

    public static func didReceive(_ bestAttemptContent: UNMutableNotificationContent?,
                                  withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        PushUNNotificationServiceExtensionHandler.didReceive(bestAttemptContent, withContentHandler: contentHandler)
    }
}

// MARK: - IYS Register Email Extension

extension RDPush {
    public static func registerEmail(email: String, permission: Bool, isCommercial: Bool = false, customDelegate: RDPushDelegate? = nil) {
        guard let shared = getShared() else { return }

        if let customDelegate = customDelegate {
            shared.delegate = customDelegate
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 60 * 60 * 3)
        setEmail(email: email, permission: permission)

        var registerEmailSubscriptionRequest: PushSubscriptionRequest!

        shared.readWriteLock.read {
            registerEmailSubscriptionRequest = shared.subscription
        }

        registerEmailSubscriptionRequest.extra?[PushProperties.CodingKeys.consentTime.rawValue] = dateFormatter.string(from: Date())
        registerEmailSubscriptionRequest.extra?[PushProperties.CodingKeys.consentSource.rawValue] = "HS_MOBIL"
        registerEmailSubscriptionRequest.extra?[PushProperties.CodingKeys.recipientType.rawValue] = isCommercial ? "TACIR" : "BIREYSEL"

        var previousRegisterEmailSubscription: PushSubscriptionRequest?
        shared.readWriteLock.read {
            previousRegisterEmailSubscription = shared.previousRegisterEmailSubscription
        }

        if registerEmailSubscriptionRequest.isValid() && (previousRegisterEmailSubscription == nil || registerEmailSubscriptionRequest != previousRegisterEmailSubscription) {
            shared.readWriteLock.write {
                shared.previousRegisterEmailSubscription = registerEmailSubscriptionRequest
            }
            RDLogger.info("Current subscription \(registerEmailSubscriptionRequest.encoded)")
        } else {
            let message = "Subscription request not ready : \(String(describing: registerEmailSubscriptionRequest))"
            RDLogger.warn(message)
            shared.delegate?.didFailRegister(error: .other(message))
            return
        }

        shared.pushAPI?.request(requestModel: registerEmailSubscriptionRequest, retry: 3, completion: shared.registerEmailHandler)
    }

    private func registerEmailHandler(result: Result<PushResponse?, PushAPIError>) {
        switch result {
        case .success:
            RDLogger.info("Register email request successfully send, token: \(String(describing: previousRegisterEmailSubscription?.token))")
            delegate?.didRegisterSuccessfully()
        case let .failure(error):
            RDLogger.error("Register email request failed : \(error)")
            delegate?.didFailRegister(error: error)
        }
    }
}

// MARK: - Graylog

extension RDPush {
    private func fillGraylogModel() {
        graylog.iosAppAlias = subscription.appKey
        graylog.token = subscription.token
        graylog.appVersion = subscription.appVersion
        graylog.sdkVersion = subscription.sdkVersion
        graylog.sdkType = subscription.sdkType
        graylog.osType = subscription.osName
        graylog.osVersion = subscription.osVersion
        graylog.deviceName = subscription.deviceName
        graylog.userAgent = userAgent
        graylog.identifierForVendor = subscription.identifierForVendor
        graylog.extra = subscription.extra
    }

    public static func sendGraylogMessage(logLevel: String, logMessage: String, _ path: String = #file, _ function: String = #function, _ line: Int = #line) {
        guard let shared = getShared() else { return }
        var emGraylogRequest: PushGraylogRequest!
        shared.readWriteLock.read {
            emGraylogRequest = shared.graylog
        }
        emGraylogRequest.logLevel = logLevel
        emGraylogRequest.logMessage = logMessage

        if let file = path.components(separatedBy: "/").last {
            emGraylogRequest.logPlace = "\(file)/\(function)/\(line)"
        } else {
            emGraylogRequest.logPlace = "\(path)/\(function)/\(line)"
        }

        shared.pushAPI?.request(requestModel: emGraylogRequest, retry: 3, completion: shared.sendGraylogMessageHandler)
    }

    private func sendGraylogMessageHandler(result: Result<PushResponse?, PushAPIError>) {
        switch result {
        case .success:
            RDLogger.info("GraylogMessage request sent successfully")
        case let .failure(error):
            RDLogger.error("GraylogMessage request failed : \(error)")
        }
    }
}
