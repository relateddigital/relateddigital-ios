//
//  VisilabsEvent.swift
//  VisilabsIOS
//
//  Created by Egemen on 7.05.2020.
//

import Foundation

class RelatedDigitalEvent {
    
    let rdProfile: RelatedDigitalProfile
    
    init(rdProfile: RelatedDigitalProfile) {
        self.rdProfile = rdProfile
    }
    
    // swiftlint:disable large_tuple function_body_length cyclomatic_complexity
    func customEvent(pageName: String? = nil,
                     properties: [String: String],
                     eventsQueue: Queue,
                     rdUser: RelatedDigitalUser,
                     channel: String) -> (eventsQueque: Queue,
                                          rdUser: RelatedDigitalUser,
                                          clearUserParameters: Bool,
                                          channel: String) {
        var props = properties
        var user = updateSessionParameters(pageName: pageName, rdUser: rdUser)
        var chan = channel
        var clearUserParameters = false
        let actualTimeOfevent = Int(Date().timeIntervalSince1970)
        
        if let cookieId = props[RelatedDigitalConstants.cookieIdKey] {
            if user.cookieId != cookieId {
                clearUserParameters = true
            }
            user.cookieId = cookieId
            props.removeValue(forKey: RelatedDigitalConstants.cookieIdKey)
        }
        
        if let exVisitorId = props[RelatedDigitalConstants.exvisitorIdKey] {
            if user.exVisitorId != exVisitorId {
                clearUserParameters = true
            }
            if user.exVisitorId != nil && user.exVisitorId != exVisitorId {
                // TO_DO: burada cookieId generate etmek doğru mu tekrar kontrol et
                user.cookieId = RelatedDigitalHelper.generateCookieId()
            }
            user.exVisitorId = exVisitorId
            props.removeValue(forKey: RelatedDigitalConstants.exvisitorIdKey)
        }
        
        if let tokenId = props[RelatedDigitalConstants.tokenIdKey] {
            user.tokenId = tokenId
            props.removeValue(forKey: RelatedDigitalConstants.tokenIdKey)
        }
        
        if let appId = props[RelatedDigitalConstants.appidKey] {
            user.appId = appId
            props.removeValue(forKey: RelatedDigitalConstants.appidKey)
        }
        
        // TO_DO: Dışarıdan mobile ad id gelince neden siliyoruz?
        if props.keys.contains(RelatedDigitalConstants.mobileIdKey) {
            props.removeValue(forKey: RelatedDigitalConstants.mobileIdKey)
        }
        
        if props.keys.contains(RelatedDigitalConstants.apiverKey) {
            props.removeValue(forKey: RelatedDigitalConstants.apiverKey)
        }
        
        if props.keys.contains(RelatedDigitalConstants.channelKey) {
            chan = props[RelatedDigitalConstants.channelKey]!
            props.removeValue(forKey: RelatedDigitalConstants.channelKey)
        }
        
        props[RelatedDigitalConstants.organizationIdKey] = self.rdProfile.organizationId
        props[RelatedDigitalConstants.profileIdKey] = self.rdProfile.profileId
        props[RelatedDigitalConstants.cookieIdKey] = user.cookieId ?? ""
        props[RelatedDigitalConstants.channelKey] = chan
        if let pageNm = pageName {
            props[RelatedDigitalConstants.uriKey] = pageNm
        }
        props[RelatedDigitalConstants.mobileApplicationKey] = RelatedDigitalConstants.isTrue
        props[RelatedDigitalConstants.mobileIdKey] = user.identifierForAdvertising ?? ""
        props[RelatedDigitalConstants.apiverKey] = RelatedDigitalConstants.ios
        props[RelatedDigitalConstants.mobileSdkVersion] = user.sdkVersion
        props[RelatedDigitalConstants.mobileAppVersion] = user.appVersion
        
        props[RelatedDigitalConstants.nrvKey] = String(user.nrv)
        props[RelatedDigitalConstants.pvivKey] = String(user.pviv)
        props[RelatedDigitalConstants.tvcKey] = String(user.tvc)
        props[RelatedDigitalConstants.lvtKey] = user.lvt
        
        if !user.exVisitorId.isNilOrWhiteSpace {
            props[RelatedDigitalConstants.exvisitorIdKey] = user.exVisitorId
        }
        
        if !user.tokenId.isNilOrWhiteSpace {
            props[RelatedDigitalConstants.tokenIdKey] = user.tokenId
        }
        
        if !user.appId.isNilOrWhiteSpace {
            props[RelatedDigitalConstants.appidKey] = user.appId
        }
        
        props[RelatedDigitalConstants.datKey] = String(actualTimeOfevent)
        
        var eQueue = eventsQueue
        
        eQueue.append(props)
        if eQueue.count > RelatedDigitalConstants.queueSize {
            eQueue.remove(at: 0)
        }
        
        return (eQueue, user, clearUserParameters, chan)
    }
    
    private func updateSessionParameters(pageName: String?, rdUser: RelatedDigitalUser) -> RelatedDigitalUser {
        var user = rdUser
        let dateNowString = RelatedDigitalHelper.formatDate(Date())
        if let lastEventTimeString = rdUser.lastEventTime {
            if isPreviousSessionOver(lastEventTimeString: lastEventTimeString, dateNowString: dateNowString) {
                user.pviv = 1
                user.tvc = user.tvc + 1
                if pageName != RelatedDigitalConstants.omEvtGif {
                    user.lastEventTime = dateNowString
                    user.lvt = dateNowString
                }
            } else {
                if pageName != RelatedDigitalConstants.omEvtGif {
                    user.pviv = user.pviv + 1
                    user.lastEventTime = dateNowString
                }
            }
            user.nrv = user.tvc > 1 ? 0 : 1
        } else {
            user.lastEventTime = dateNowString
            user.nrv = 1
            user.pviv = 1
            user.tvc = 1
            user.lvt = dateNowString
        }
        return user
    }
    
    private func isPreviousSessionOver(lastEventTimeString: String, dateNowString: String) -> Bool {
        if let lastEventTime = RelatedDigitalHelper.parseDate(lastEventTimeString), let dateNow = RelatedDigitalHelper.parseDate(dateNowString) {
            if Int(dateNow.timeIntervalSince1970) - Int(lastEventTime.timeIntervalSince1970) > (60 * 30) {
                return true
            }
        }
        return false
    }
    
}
