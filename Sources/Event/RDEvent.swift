//
//  RDEvent.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.01.2021.
//

import Foundation

class RDEvent {
    // swiftlint:disable large_tuple function_body_length cyclomatic_complexity
    func customEvent(pageName: String? = nil, properties: Properties, eventsQueue: Queue, rdUser: RDUser, channel: String) -> (eventsQueque: Queue, rdUser: RDUser, clearUserParameters: Bool, channel: String) {
        var props = properties
        var user = updateSessionParameters(pageName: pageName, rdUser: rdUser)
        var chan = channel
        var clearUserParameters = false
        let actualTimeOfevent = Int(Date().timeIntervalSince1970)
        let appGroupsKey = UserDefaults.standard.string(forKey: "appGroupsKey")
        let deviceLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first
        let regionCode = Locale.current.regionCode
        let system = UIDevice.current
        let screenSize = UIScreen.main.bounds.size
        

        if let cookieId = props[RDConstants.cookieIdKey] {
            if user.cookieId != cookieId {
                clearUserParameters = true
            }
            user.cookieId = cookieId
            props.removeValue(forKey: RDConstants.cookieIdKey)
        }

        if let exVisitorId = props[RDConstants.exvisitorIdKey] {
            if user.exVisitorId != exVisitorId {
                clearUserParameters = true
            }
            if user.exVisitorId != nil && user.exVisitorId != exVisitorId {
                // TO_DO: burada cookieId generate etmek doğru mu tekrar kontrol et
                user.cookieId = RDHelper.generateCookieId()
            }
            user.exVisitorId = exVisitorId
            props.removeValue(forKey: RDConstants.exvisitorIdKey)
        }

        if let tokenId = props[RDConstants.tokenIdKey] {
            user.tokenId = tokenId
            props.removeValue(forKey: RDConstants.tokenIdKey)
        }

        if let appId = props[RDConstants.appidKey] {
            user.appId = appId
            props.removeValue(forKey: RDConstants.appidKey)
        }

        // TO_DO: Dışarıdan mobile ad id gelince neden siliyoruz?
        if props.keys.contains(RDConstants.mobileIdKey) {
            props.removeValue(forKey: RDConstants.mobileIdKey)
        }

        if props.keys.contains(RDConstants.apiverKey) {
            props.removeValue(forKey: RDConstants.apiverKey)
        }

        if props.keys.contains(RDConstants.channelKey) {
            chan = props[RDConstants.channelKey]!
            props.removeValue(forKey: RDConstants.channelKey)
        }

        if props.keys.contains(RDConstants.utmCampaignKey) {
            print("utmCampaignKey")
            user.utmCampaign = props[RDConstants.utmCampaignKey]
            props.removeValue(forKey: RDConstants.utmCampaignKey)
        }

        if props.keys.contains(RDConstants.utmMediumKey) {
            print("utmMediumKey")
            user.utmMedium = props[RDConstants.utmMediumKey]
            props.removeValue(forKey: RDConstants.utmMediumKey)
        }

        if props.keys.contains(RDConstants.utmSourceKey) {
            user.utmSource = props[RDConstants.utmSourceKey]
            props.removeValue(forKey: RDConstants.utmSourceKey)
        }

        if props.keys.contains(RDConstants.utmContentKey) {
            user.utmContent = props[RDConstants.utmContentKey]
            props.removeValue(forKey: RDConstants.utmContentKey)
        }

        if props.keys.contains(RDConstants.utmTermKey) {
            user.utmTerm = props[RDConstants.utmTermKey]
            props.removeValue(forKey: RDConstants.utmTermKey)
        }

        if props.keys.contains(RDConstants.isPushUser) {
            user.isPushUser = props[RDConstants.isPushUser]
            props.removeValue(forKey: RDConstants.isPushUser)
        }

        if props.keys.contains(RDConstants.pushTime) {
            user.pushTime = props[RDConstants.pushTime]
            props.removeValue(forKey: RDConstants.pushTime)
        }

        props[RDConstants.organizationIdKey] = RelatedDigital.rdProfile.organizationId
        props[RDConstants.profileIdKey] = RelatedDigital.rdProfile.profileId
        props[RDConstants.cookieIdKey] = user.cookieId ?? ""
        props[RDConstants.channelKey] = chan
        if let pageNm = pageName {
            props[RDConstants.uriKey] = pageNm
        }
        props[RDConstants.mobileApplicationKey] = RDConstants.isTrue
        props[RDConstants.mobileIdKey] = user.identifierForAdvertising ?? ""
        props[RDConstants.apiverKey] = RDConstants.ios
        props[RDConstants.mobileSdkVersion] = user.sdkVersion
        props[RDConstants.mobileSdkType] = user.sdkType
        props[RDConstants.mobileAppVersion] = user.appVersion

        props[RDConstants.nrvKey] = String(user.nrv)
        props[RDConstants.pvivKey] = String(user.pviv)
        props[RDConstants.tvcKey] = String(user.tvc)
        props[RDConstants.lvtKey] = user.lvt

        
        if !deviceLanguage.isNilOrWhiteSpace {
            props[RDConstants.deviceLanguage] = deviceLanguage
        }
        
        if !regionCode.isNilOrWhiteSpace && !deviceLanguage.isNilOrWhiteSpace {
            props[RDConstants.deviceRegion] = "\(deviceLanguage!)_\(regionCode!)"
        }
        
        if !system.systemVersion.isEmptyOrWhitespace {
            props[RDConstants.systemVersion] = system.systemVersion
        }
        
        if !system.systemName.isEmptyOrWhitespace {
            props[RDConstants.systemName] = system.systemName
        }
        
        if !screenSize.equalTo(CGSize.zero) {
            let screenWidth = Int(screenSize.width)
            let screenHeight = Int(screenSize.height)
            props[RDConstants.screenSize] = "\(screenWidth)x\(screenHeight)"
        }

        if !user.exVisitorId.isNilOrWhiteSpace {
            props[RDConstants.exvisitorIdKey] = user.exVisitorId
        }

        if !user.tokenId.isNilOrWhiteSpace {
            props[RDConstants.tokenIdKey] = user.tokenId
        }

        if !user.appId.isNilOrWhiteSpace {
            props[RDConstants.appidKey] = user.appId
        }

        if !user.utmCampaign.isNilOrWhiteSpace {
            props[RDConstants.utmCampaignKey] = user.utmCampaign
        }

        if !user.utmMedium.isNilOrWhiteSpace {
            props[RDConstants.utmMediumKey] = user.utmMedium
        }

        if !user.utmSource.isNilOrWhiteSpace {
            props[RDConstants.utmSourceKey] = user.utmSource
        }

        if !user.utmContent.isNilOrWhiteSpace {
            props[RDConstants.utmContentKey] = user.utmContent
        }

        if !user.utmTerm.isNilOrWhiteSpace {
            props[RDConstants.utmTermKey] = user.utmTerm
        }

        if !user.isPushUser.isNilOrWhiteSpace {
            if !user.pushTime.isNilOrWhiteSpace {
                let referenceDateString = user.pushTime!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
                if let referenceDate = dateFormatter.date(from: referenceDateString) {
                    
                    let currentDate = Date()

                    if let date30MinutesLater = Calendar.current.date(byAdding: .minute, value: 30, to: referenceDate) {
                        if currentDate >= date30MinutesLater {
                            props[RDConstants.isPushUser] = nil
                            props[RDConstants.pushTime] = nil
                        } else {
                            props[RDConstants.isPushUser] = user.isPushUser
                            props[RDConstants.pushTime] = user.pushTime
                        }
                    }
                }
            }
        }

        props[RDConstants.datKey] = String(actualTimeOfevent)
        

        var eQueue = eventsQueue

        eQueue.append(props)
        if eQueue.count > RDConstants.queueSize {
            eQueue.remove(at: 0)
        }

        return (eQueue, user, clearUserParameters, chan)
    }

    private func updateSessionParameters(pageName: String?, rdUser: RDUser) -> RDUser {
        var user = rdUser
        let dateNowString = RDHelper.formatDate(Date())
        if let lastEventTimeString = rdUser.lastEventTime {
            if isPreviousSessionOver(lastEventTimeString: lastEventTimeString, dateNowString: dateNowString) {
                user.pviv = 1
                user.tvc = user.tvc + 1
                if pageName != RDConstants.omEvtGif {
                    user.lastEventTime = dateNowString
                    user.lvt = dateNowString
                }
                user.utmCampaign = nil
                user.utmContent = nil
                user.utmMedium = nil
                user.utmSource = nil
                user.utmTerm = nil
            } else {
                if pageName != RDConstants.omEvtGif {
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
        if let lastEventTime = RDHelper.parseDate(lastEventTimeString), let dateNow = RDHelper.parseDate(dateNowString) {
            if Int(dateNow.timeIntervalSince1970) - Int(lastEventTime.timeIntervalSince1970) > (60 * 30) {
                return true
            }
        }
        return false
    }
}
