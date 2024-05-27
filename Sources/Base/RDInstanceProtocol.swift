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
    var geofenceEnabled: Bool { get set }
    var askLocationPermissionAtStart: Bool {get set}
    func requestIDFA()
    func sendLocationPermission()
    func requestLocationPermissions()
    func sendCampaignParameters(properties: Properties)
    func customEvent(_ pageName: String, properties: Properties)
    func login(exVisitorId: String, properties: Properties)
    func signUp(exVisitorId: String, properties: Properties)
    func logout()
    func showNotification(_ relatedDigitalInAppNotification: RDInAppNotification)
    func subscribeSpinToWinMail(actid: String, auth: String, mail: String)
    func subscribeGamificationMail(actid: String, auth: String, mail: String)
    func subscribeFindToWinMail(actid: String, auth: String, mail: String)
    func subscribeGiftBoxMail(actid: String, auth: String, mail: String)
    func subscribeJackpotMail(actid: String, auth: String, mail: String)
    func subscribeChooseFavoriteMail(actid: String, auth: String, mail: String)
    func subscribeMail(click: String, actid: String, auth: String, mail: String)
    func trackSpinToWinClick(spinToWinReport: SpinToWinReport)
    func trackGamificationClick(gameficationReport: GameficationReport)
    func trackFindToWinClick(findToWinReport: FindToWinReport)
    func trackGiftBoxClick(giftBoxReport: GiftBoxReport)
    func trackScratchToWinClick(scratchToWinReport: TargetingActionReport)
    func trackJackpotClick(jackpotReport: JackpotReport)
    func trackChooseFavoriteClick(chooseFavoriteReport: ChooseFavoriteReport)
    func trackCustomWebviewClick(customWebviewReport: CustomWebViewReport)
    func trackDrawerClick(drawerReport: DrawerReport)
    func trackRecommendationClick(qs: String)
    func getStoryView(actionId: Int?, urlDelegate: RDStoryURLDelegate?) -> RDStoryHomeView
    func getStoryViewAsync(actionId: Int?, urlDelegate: RDStoryURLDelegate?, completion: @escaping StoryCompletion)
    func getBannerView(properties: Properties, completion: @escaping ((BannerView?) -> Void))
    func getButtonCarouselView(properties: Properties, completion: @escaping ((ButtonCarouselView?) -> Void))
    func getNpsWithNumbersView(properties: Properties, delegate: RDNpsWithNumbersDelegate?, completion: @escaping ((RDNpsWithNumbersContainerView?) -> Void))
    func recommend(zoneId: String, productCode: String?, filters: [RDRecommendationFilter], properties: Properties, completion: @escaping RecommendCompletion)
    func getFavoriteAttributeActions(actionId: Int?, completion: @escaping FavoriteAttributeActionCompletion)
    func enablePushNotifications(appAlias: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]?, appGroupsKey: String?, deliveredBadge: Bool?)
    func askForNotificationPermission(register: Bool)
    func deleteNotifications()
    func removeNotification(withPushID pushID: String, completion: @escaping (Bool) -> Void)
    func askForNotificationPermissionProvisional(register: Bool)
    func registerForPushNotifications()
    func setPushNotification(permission: Bool)
    func setPhoneNumber(msisdn: String?, permission: Bool)
    func setEmail(email: String?, permission: Bool)
    func setEmail(email: String?)
    func setEuroUserId(userKey: String?)
    func setAnonymous(permission: Bool)
    func setAppVersion(appVersion: String?)
    func setTwitterId(twitterId: String?)
    func setAdvertisingIdentifier(adIdentifier: String?)
    func setFacebook(facebookId: String?)
    func setUserProperty(key: String, value: String?)
    func removeUserProperty(key: String)
    func setBadge(count: Int)
    func registerToken(tokenData: Data?)
    func handlePush(pushDictionary: [AnyHashable: Any])
    func handlePushWithActionButtons(response : UNNotificationResponse,type:Any)
    func sync(notification: Notification?)
    func registerEmail(email: String, permission: Bool, isCommercial: Bool, customDelegate: RDPushDelegate?)
    func getPushMessages(completion: @escaping GetPushMessagesCompletion)
    func getPushMessagesWithID(completion: @escaping GetPushMessagesCompletion)
    func getToken(completion: @escaping ((_ token: String) -> Void))
    func readAllPushMessages(completion: @escaping ((_ success: Bool) -> Void))
    func readAllPushMessagesWithId(pushId: String?, completion: @escaping ((_ success: Bool) -> Void))
}

