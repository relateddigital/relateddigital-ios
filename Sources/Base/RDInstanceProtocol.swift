//
//  RDInstanceProtocol.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.02.2022.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit
import UserNotifications

public typealias UIA = UIApplication
typealias NC = NotificationCenter
typealias UNUNC = UNUserNotificationCenter

public typealias Properties = [String: String]
typealias Queue = [Properties]
public typealias StoryCompletion = (RDStoryHomeView?) -> Void
public typealias RecommendCompletion = (RDRecommendationResponse) -> Void
public typealias FavoriteAttributeActionCompletion = (RDFavoriteAttributeActionResponse) -> Void
public typealias GetPushMessagesCompletion = ([RDPushMessage]) -> Void

protocol RDInstanceProtocol {
    var exVisitorId: String? { get }
    var rdUser: RDUser { get }
    var rdProfile: RDProfile { get }
    var locationServicesEnabledForDevice: Bool { get }
    var locationServiceStateStatusForApplication: RDCLAuthorizationStatus { get }
    var inappButtonDelegate: RDInappButtonDelegate? { get set }
    var loggingEnabled: Bool { get set }
    var inAppNotificationsEnabled: Bool { get set }
    func requestIDFA()
    func sendLocationPermission()
    func customEvent(_ pageName: String, properties: Properties)
    func login(exVisitorId: String, properties: Properties)
    func signUp(exVisitorId: String, properties: Properties)
    func logout()
    func showNotification(_ relatedDigitalInAppNotification: RDInAppNotification)
    func subscribeSpinToWinMail(actid: String, auth: String, mail: String)
    func subscribeMail(click: String, actid: String, auth: String, mail: String)
    func trackSpinToWinClick(spinToWinReport: SpinToWinReport)
    func trackRecommendationClick(qs: String)
    func getStoryView(actionId: Int?, urlDelegate: RDStoryURLDelegate?) -> RDStoryHomeView
    func getStoryViewAsync(actionId: Int?, urlDelegate: RDStoryURLDelegate?, completion: @escaping StoryCompletion)
    func recommend(zoneId: String, productCode: String?, filters: [RDRecommendationFilter], properties: Properties, completion: @escaping RecommendCompletion)
    func getFavoriteAttributeActions(actionId: Int?, completion: @escaping FavoriteAttributeActionCompletion)
    func enablePushNotifications(appAlias: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]?, appGroupsKey: String?)
    func askForNotificationPermission(register: Bool)
    func askForNotificationPermissionProvisional(register: Bool)
    func registerForPushNotifications()
    func setPushNotification(permission: Bool)
    func setPhoneNumber(msisdn: String?, permission: Bool)
    func setEmail(email: String?, permission: Bool)
    func setEmail(email: String?)
    func setEuroUserId(userKey: String?)
    func setAppVersion(appVersion: String?)
    func setTwitterId(twitterId: String?)
    func setAdvertisingIdentifier(adIdentifier: String?)
    func setFacebook(facebookId: String?)
    func setUserProperty(key: String, value: String?)
    func removeUserProperty(key: String)
    func setBadge(count: Int)
    func registerToken(tokenData: Data?)
    func handlePush(pushDictionary: [AnyHashable: Any])
    func sync(notification: Notification?)
    func registerEmail(email: String, permission: Bool, isCommercial: Bool, customDelegate: RDPushDelegate?)
    func getPushMessages(completion: @escaping GetPushMessagesCompletion)
}

