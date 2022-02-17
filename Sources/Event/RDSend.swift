//
//  RDSend.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 13.01.2022.
//

import Foundation

class RDSend {

    // TO_DO: burada internet bağlantısı kontrolü yapmaya gerek var mı?
    func sendEventsQueue(_ eventsQueue: Queue, rdUser: RDUser, rdCookie: RDCookie) -> RDCookie {
        var mutableCookie = rdCookie

        for counter in 0..<eventsQueue.count {
            let event = eventsQueue[counter]
            RDLogger.debug("Sending event")
            RDLogger.debug(event)
            let loggerHeaders = prepareHeaders(.logger, event: event, rdUser: rdUser, rdCookie: rdCookie)
            let realTimeHeaders = prepareHeaders(.realtime, event: event, rdUser: rdUser, rdCookie: rdCookie)

            let loggerSemaphore = DispatchSemaphore(value: 0)
            let realTimeSemaphore = DispatchSemaphore(value: 0)
            RDRequest.sendEventRequest(rdEndpoint: .logger, properties: event, headers: loggerHeaders,
                                             completion: { [loggerSemaphore] cookies in
                                        if let cookies = cookies {
                                            for cookie in cookies {
                                                if cookie.key.contains(RDConstants.loadBalancePrefix,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.loggerCookieKey = cookie.key
                                                    mutableCookie.loggerCookieValue = cookie.value
                                                }
                                                if cookie.key.contains(RDConstants.om3Key,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.loggerOM3rdCookieValue = cookie.value
                                                }
                                            }
                                        }
                                        loggerSemaphore.signal()
            })

            RDRequest.sendEventRequest(rdEndpoint: .realtime, properties: event, headers: realTimeHeaders,
                                             completion: { [realTimeSemaphore] cookies in
                                        if let cookies = cookies {
                                            for cookie in cookies {
                                                if cookie.key.contains(RDConstants.loadBalancePrefix,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.realTimeCookieKey = cookie.key
                                                    mutableCookie.realTimeCookieValue = cookie.value
                                                }
                                                if cookie.key.contains(RDConstants.om3Key,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.realTimeOM3rdCookieValue = cookie.value
                                                }
                                            }
                                        }
                                        realTimeSemaphore.signal()
            })

            _ = loggerSemaphore.wait(timeout: DispatchTime.distantFuture)
            _ = realTimeSemaphore.wait(timeout: DispatchTime.distantFuture)
        }

        return mutableCookie
    }

    private func prepareHeaders(_ rdEndpoint: RDEndpoint, event: [String: String], rdUser: RDUser, rdCookie: RDCookie) -> [String: String] {
        var headers = [String: String]()
        headers["Referer"] = event[RDConstants.uriKey] ?? ""
        headers["User-Agent"] = rdUser.userAgent
        if let cookie = prepareCookie(rdEndpoint, rdCookie: rdCookie) {
            headers["Cookie"] = cookie
        }
        return headers
    }

    private func prepareCookie(_ rdEndpoint: RDEndpoint, rdCookie: RDCookie) -> String? {
        var cookieString: String?
        if rdEndpoint == .logger {
            if let key = rdCookie.loggerCookieKey, let value = rdCookie.loggerCookieValue {
                cookieString = "\(key)=\(value)"
            }
            if let om3rdValue = rdCookie.loggerOM3rdCookieValue {
                if !cookieString.isNilOrWhiteSpace {
                    cookieString = cookieString! + ";"
                } else { // TO_DO: bu kısmı güzelleştir
                    cookieString = ""
                }
                cookieString = cookieString! + "\(RDConstants.om3Key)=\(om3rdValue)"
            }
        }
        if rdEndpoint == .realtime {
            if let key = rdCookie.realTimeCookieKey, let value = rdCookie.realTimeCookieValue {
                cookieString = "\(key)=\(value)"
            }
            if let om3rdValue = rdCookie.realTimeOM3rdCookieValue {
                if !cookieString.isNilOrWhiteSpace {
                    cookieString = cookieString! + ";"
                } else { // TO_DO: bu kısmı güzelleştir
                    cookieString = ""
                }
                cookieString = cookieString! + "\(RDConstants.om3Key)=\(om3rdValue)"
            }
        }
        return cookieString
    }
}
