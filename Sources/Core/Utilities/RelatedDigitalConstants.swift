//
//  RelatedDigitalConstants.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation
import UIKit


struct RelatedDigitalConstants {
    static let http = "http"
    static let https = urlConstant.shared.securityTag
    static let dateFormat = "yyyy-MM-dd HH:mm:ss"
    static let sdkVersion = "0.0.1"
    static let loggerEndPoint = "lgr.visilabs.net"
    static let realtimeEndPoint = "rt.visilabs.net"
    static var recommendationEndPoint = "\(urlConstant.shared.urlPrefix)/json"
    static var actionEndPoint = "\(urlConstant.shared.urlPrefix)/actjson"
    static var geofenceEndPoint = "\(urlConstant.shared.urlPrefix)/geojson"
    static var mobileEndPoint = "\(urlConstant.shared.urlPrefix)/mobile"
    static var subsjsonEndpoint = "\(urlConstant.shared.urlPrefix)/subsjson"
    static var promotionEndpoint = "\(urlConstant.shared.urlPrefix)/promotion"
    static let subscriptionEndpoint = "pushs.euromsg.com/subscription"
    static var retentionEndpoint = "pushr.euromsg.com/retention"
    static var remoteConfigEndpoint = "mbls.visilabs.net/rc.json"
    static let queueSize = 5000

    // MARK: - UserDefaults Keys

    static let userDefaultsProfileKey = "Visilabs.profile"
    static let userDefaultsUserKey = "Visilabs.user"
    static let userDefaultsGeofenceHistoryKey = "Visilabs.geofenceHistory"
    static let userDefaultsTargetKey = "Visilabs.target"

    // MARK: - Archive Keys

    static let geofenceHistoryArchiveKey = "Visilabs.geofenceHistory"
    static let userArchiveKey = "Visilabs.user"
    static let profileArchiveKey = "Visilabs.profile"

    static let cookieidArchiveKey = "Visilabs.cookieId"
    // "Visilabs.identity" idi cookieID olarak değiştirmek nasıl sorunlara sebep olur düşün.
    static let identityArchiveKey = "Visilabs.identity"
    static let exvisitorIdArchiveKey = "Visilabs.exVisitorId"
    static let tokenidArchiveKey = "Visilabs.tokenId"
    static let appidArchiveKey = "Visilabs.appId"
    static let useragentArchiveKey = "Visilabs.userAgent"

    static let maxGeofenceCountKey = "maxGeofenceCount"
    static let inAppNotificaitionsKey = "inAppNotificationsEnabled"
    static let geofenceEnabledKey = "geofenceEnabled"
    static let requestTimeoutInSecondsKey = "requestTimeoutInSeconds"
    static let dataSourceKey = "dataSource"
    static let userAgentKey = "OM.userAgent"
    static let visitorData = "visitorData"
    
    static let mobileIdKey = "OM.m_adid"
    static let mobileApplicationKey = "OM.mappl"
    static let mobileSdkVersion = "sdk_version"
    static let mobileAppVersion = "OM.appVersion"

    static let isTrue = "true"

    static let ios = "IOS"
    static let datKey = "dat"
    static let omGif = "om.gif"
    static let domainkey = "OM.domain"
    static let visitCappingKey = "OM.vcap"
    static let visitorCappingKey = "OM.viscap"
    static let omEvtGif = "OM_evt.gif"
    
    static let organizationIdKey = "OM.oid"
    static let profileIdKey = "OM.siteID"
    static let cookieIdKey = "OM.cookieID"
    static let exvisitorIdKey = "OM.exVisitorID"
    static let zoneIdKey = "OM.zid"
    static let bodyKey = "OM.body"
    static let latitudeKey = "OM.latitude"
    static let longitudeKey = "OM.longitude"
    static let actidKey = "actid"
    static let actKey = "act"
    static let tokenIdKey = "OM.sys.TokenID"
    static let appidKey = "OM.sys.AppID"
    static let loggerUrl = "lgr.visilabs.net"
    static let realTimeUrl = "rt.visilabs.net"
    static let loadBalancePrefix = "NSC"
    static let om3Key = "OM.3rd"
    static let filterKey = "OM.w.f"
    static let apiverKey = "OM.apiver"
    static let geoIdKey = "OM.locationid"
    static let triggerEventKey = "OM.triggerevent"
    static let subscribedEmail = "OM.subsemail"
    
    static let channelKey = "OM.vchannel"
    static let uriKey = "OM.uri"
    
    static let lastEventTimeKey = "lastEventTime"
    static let nrvKey = "OM.nrv"
    static let pvivKey = "OM.pviv"
    static let tvcKey = "OM.tvc"
    static let lvtKey = "OM.lvt"
    
    static let getList = "getlist"
    static let processV2 = "processV2"
    static let onEnter = "OnEnter"
    static let onExit = "OnExit"
    static let dwell = "Dwell"
    static let apiverValue = "IOS"
    
    private static let targetPrefVossStoreKey = "OM.voss"
    private static let targetPrefVcnameStoreKey = "OM.vcname"
    private static let targetPrefVcmediumStoreKey = "OM.vcmedium"
    private static let targetPrefVcsourceStoreKey = "OM.vcsource"
    private static let targetPrefVseg1StoreKey = "OM.vseg1"
    private static let targetPrefVseg2StoreKey = "OM.vseg2"
    private static let targetPrefVseg3StoreKey = "OM.vseg3"
    private static let targetPrefVseg4StoreKey = "OM.vseg4"
    private static let targetPrefVseg5StoreKey = "OM.vseg5"
    private static let targetPrefBdStoreKey = "OM.bd"
    private static let targetPrefGnStoreKey = "OM.gn"
    private static let targetPrefLocStoreKey = "OM.loc"
    private static let targetPrefVPVStoreKey = "OM.vpv"
    private static let targetPrefLPVSStoreKey = "OM.lpvs"
    private static let targetPrefLPPStoreKey = "OM.lpp"
    private static let targetPrefVQStoreKey = "OM.vq"
    private static let targetPrefVRStoreKey = "OM.vrDomain"

    private static let targetPrefVossKey = "OM.OSS"
    private static let targetPrefVcNameKey = "OM.cname"
    private static let targetPrefVcmediumKey = "OM.cmedium"
    private static let targetPrefVcsourceKey = "OM.csource"
    private static let targetPrefVseg1Key = "OM.vseg1"
    private static let targetPrefVseg2Key = "OM.vseg2"
    private static let targetPrefVseg3Key = "OM.vseg3"
    private static let targetPrefVseg4Key = "OM.vseg4"
    private static let targetPrefVseg5Key = "OM.vseg5"
    private static let targetPrefBDKey = "OM.bd"
    private static let targetPrefGNKey = "OM.gn"
    private static let targetPrefLOCKey = "OM.loc"
    private static let targetPrefVPVKey = "OM.pv"
    private static let targetPrefLPVSKey = "OM.pv"
    private static let targetPrefLPPKey = "OM.pp"
    private static let targetPrefVQKey = "OM.q"
    private static let targetPrefVRDomainKey = "OM.rDomain"
    private static let targetPrefPPRKey = "OM.ppr"
    
    private static var targetParameters = [RelatedDigitalParameter]()

    static func relatedDigitalTargetParameters() -> [RelatedDigitalParameter] {
        if targetParameters.count == 0 {
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVossKey, storeKey: targetPrefVossStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVcNameKey, storeKey: targetPrefVcnameStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVcmediumKey, storeKey: targetPrefVcmediumStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVcsourceKey, storeKey: targetPrefVcsourceStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVseg1Key, storeKey: targetPrefVseg1StoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVseg2Key, storeKey: targetPrefVseg2StoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVseg3Key, storeKey: targetPrefVseg3StoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVseg4Key, storeKey: targetPrefVseg4StoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVseg5Key, storeKey: targetPrefVseg5StoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefBDKey, storeKey: targetPrefBdStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefGNKey, storeKey: targetPrefGnStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefLOCKey, storeKey: targetPrefLocStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVPVKey, storeKey: targetPrefVPVStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefLPVSKey, storeKey: targetPrefLPVSStoreKey,
                                                      count: 10, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefLPPKey, storeKey: targetPrefLPPStoreKey,
                                                      count: 1, relatedKeys: [targetPrefPPRKey]))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVQKey, storeKey: targetPrefVQStoreKey,
                                                      count: 1, relatedKeys: nil))
            targetParameters.append(RelatedDigitalParameter(key: targetPrefVRDomainKey, storeKey: targetPrefVRStoreKey,
                                                      count: 1, relatedKeys: nil))
        }
        return targetParameters
    }
}
