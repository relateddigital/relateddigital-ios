//
//  RelatedDigitalSend.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 20.12.2021.
//

import Foundation

protocol RelatedDigitalSendDelegate: AnyObject {
    func send(completion: (() -> Void)?)
    func updateNetworkActivityIndicator(_ isOn: Bool)
}

class RelatedDigitalSend {

    // TO_DO: bu delegate kullanılmıyor. kaldır.
    weak var delegate: RelatedDigitalSendDelegate?

    // TO_DO: burada internet bağlantısı kontrolü yapmaya gerek var mı?
    func sendEventsQueue(_ eventsQueue: Queue, relatedDigitalUser: RelatedDigitalUser,
                                                  relatedDigitalCookie: RelatedDigitalLoadBalancerCookie, timeoutInterval: TimeInterval) -> RelatedDigitalLoadBalancerCookie {
        var mutableCookie = relatedDigitalCookie

        for counter in 0..<eventsQueue.count {
            let event = eventsQueue[counter]
            RelatedDigitalLogger.debug("Sending event")
            RelatedDigitalLogger.debug(event)
            let loggerHeaders = prepareHeaders(.logger, event: event, RelatedDigitalUser: relatedDigitalUser,
                                                                                              RelatedDigitalCookie:relatedDigitalCookie)
            let realTimeHeaders = prepareHeaders(.realtime, event: event, RelatedDigitalUser: relatedDigitalUser,
                                                                                                RelatedDigitalCookie:relatedDigitalCookie)

            let loggerSemaphore = DispatchSemaphore(value: 0)
            let realTimeSemaphore = DispatchSemaphore(value: 0)
            // delegate?.updateNetworkActivityIndicator(true)
            RelatedDigitalRequest.sendEventRequest(RelatedDigitalEndpoint: .logger, properties: event,
                                             headers: loggerHeaders, timeoutInterval: timeoutInterval,
                                             completion: { [loggerSemaphore] cookies in
                                        // self.delegate?.updateNetworkActivityIndicator(false)
                                        if let cookies = cookies {
                                            for cookie in cookies {
                                                if cookie.key.contains(RelatedDigitalConstants.loadBalancePrefix,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.loggerCookieKey = cookie.key
                                                    mutableCookie.loggerCookieValue = cookie.value
                                                }
                                                if cookie.key.contains(RelatedDigitalConstants.om3Key,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.loggerOM3rdCookieValue = cookie.value
                                                }
                                            }
                                        }
                                        loggerSemaphore.signal()
            })

            RelatedDigitalRequest.sendEventRequest(RelatedDigitalEndpoint: .realtime, properties: event,
                                             headers: realTimeHeaders, timeoutInterval: timeoutInterval,
                                             completion: { [realTimeSemaphore] cookies in
                                        // self.delegate?.updateNetworkActivityIndicator(false)
                                        if let cookies = cookies {
                                            for cookie in cookies {
                                                if cookie.key.contains(RelatedDigitalConstants.loadBalancePrefix,
                                                                       options: .caseInsensitive) {
                                                    mutableCookie.realTimeCookieKey = cookie.key
                                                    mutableCookie.realTimeCookieValue = cookie.value
                                                }
                                                if cookie.key.contains(RelatedDigitalConstants.om3Key,
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

    private func prepareHeaders(_ RelatedDigitalEndpoint: RelatedDigitalEndpoint, event: [String: String],
                                RelatedDigitalUser: RelatedDigitalUser,RelatedDigitalCookie: RelatedDigitalLoadBalancerCookie) -> [String: String] {
        var headers = [String: String]()
        headers["Referer"] = event[RelatedDigitalConstants.uriKey] ?? ""
        headers["User-Agent"] = RelatedDigitalUser.userAgent
        if let cookie = prepareCookie(RelatedDigitalEndpoint, RelatedDigitalCookie: RelatedDigitalCookie) {
            headers["Cookie"] = cookie
        }
        return headers
    }

    private func prepareCookie(_ RelatedDigitalEndpoint: RelatedDigitalEndpoint, RelatedDigitalCookie: RelatedDigitalLoadBalancerCookie) -> String? {
        var cookieString: String?
        if RelatedDigitalEndpoint == .logger {
            if let key = RelatedDigitalCookie.loggerCookieKey, let value = RelatedDigitalCookie.loggerCookieValue {
                cookieString = "\(key)=\(value)"
            }
            if let om3rdValue = RelatedDigitalCookie.loggerOM3rdCookieValue {
                if !cookieString.isNilOrWhiteSpace {
                    cookieString = cookieString! + ";"
                } else { // TO_DO: bu kısmı güzelleştir
                    cookieString = ""
                }
                cookieString = cookieString! + "\(RelatedDigitalConstants.om3Key)=\(om3rdValue)"
            }
        }
        if RelatedDigitalEndpoint == .realtime {
            if let key = RelatedDigitalCookie.realTimeCookieKey, let value = RelatedDigitalCookie.realTimeCookieValue {
                cookieString = "\(key)=\(value)"
            }
            if let om3rdValue = RelatedDigitalCookie.realTimeOM3rdCookieValue {
                if !cookieString.isNilOrWhiteSpace {
                    cookieString = cookieString! + ";"
                } else { // TO_DO: bu kısmı güzelleştir
                    cookieString = ""
                }
                cookieString = cookieString! + "\(RelatedDigitalConstants.om3Key)=\(om3rdValue)"
            }
        }
        return cookieString
    }
}
