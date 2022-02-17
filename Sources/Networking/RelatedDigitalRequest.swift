//
//  VisilabsRequest.swift
//  VisilabsIOS
//
//  Created by Egemen on 6.08.2020.
//

import Foundation

class RelatedDigitalRequest {
    
    // MARK: - EVENT
    
    class func sendEventRequest(relatedDigitalEndpoint: RDEndpoint,
                                properties: [String: String],
                                headers: [String: String],
                                timeoutInterval: TimeInterval,
                                completion: @escaping ([String: String]?) -> Void) {
        
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: relatedDigitalEndpoint,
                                                     method: .get,
                                                     timeoutInterval: timeoutInterval,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: headers,
                                                     parse: {_ in return true})
        
        sendEventRequestHandler(resource: resource, completion: { success in completion(success) })
    }
    
    private class func sendEventRequestHandler(resource: RDResource<Bool>,
                                               completion: @escaping ([String: String]?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, response) in
            
            var requestUrl = RelatedDigitalBasePath.getEndpoint(relatedDigitalEndpoint: resource.endPoint)
            if let httpResponse = response as? HTTPURLResponse {
                if let url = httpResponse.url {
                    requestUrl = url.absoluteString
                }
            }
            RDLogger.error("API request to \(requestUrl) has failed with error \(error)")
            completion(nil)
        }, success: { (_, response) in
            
            if let httpResponse = response as? HTTPURLResponse, let url = httpResponse.url {
                RDLogger.info("\(url.absoluteString) request sent successfully")
                let cookies = getCookies(url)
                completion(cookies)
            } else {
                let end = RelatedDigitalBasePath.getEndpoint(relatedDigitalEndpoint: resource.endPoint)
                RDLogger.error("\(end) can not convert to HTTPURLResponse")
                completion(nil)
            }
            
        })
    }
    
    private class func getCookies(_ url: URL) -> [String: String] {
        var cookieKeyValues = [String: String]()
        for cookie in RDHelper.readCookie(url) {
            if cookie.name.contains(RDConstants.loadBalancePrefix, options: .caseInsensitive) {
                cookieKeyValues[cookie.name] = cookie.value
            }
            if cookie.name.contains(RDConstants.om3Key, options: .caseInsensitive) {
                cookieKeyValues[cookie.name] = cookie.value
            }
        }
        return cookieKeyValues
    }
    
    // MARK: - RECOMMENDATION
    
    // TO_DO: completion Any mi olmalı, yoksa AnyObject mi?
    class func sendRecommendationRequest(properties: [String: String],
                                         headers: [String: String],
                                         timeoutInterval: TimeInterval,
                                         completion: @escaping ([Any]?, RelatedDigitalError?) -> Void) {
        
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }
        
        let responseParser: (Data) -> [Any]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding api data")
            }
            return response as? [Any]
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: .target,
                                                     method: .get,
                                                     timeoutInterval: timeoutInterval,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: headers,
                                                     parse: responseParser)
        
        sendRecommendationRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
        
    }
    
    private class func sendRecommendationRequestHandler(resource: RDResource<[Any]>,
                                                        completion: @escaping ([Any]?, RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { (result, _) in
            completion(result, nil)
        })
    }
    
    // MARK: - TARGETING ACTIONS
    
    // MARK: - Geofence
    
    class func sendGeofenceRequest(properties: [String: String],
                                   headers: [String: String],
                                   timeoutInterval: TimeInterval,
                                   completion: @escaping ([[String: Any]]?, RelatedDigitalError?) -> Void) {
        
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }
        
        if properties[RDConstants.actKey] == RDConstants.getList {
            let responseParserGetList: (Data) -> [[String: Any]]? = { data in
                var response: Any?
                do {
                    response = try JSONSerialization.jsonObject(with: data, options: [])
                } catch {
                    RDLogger.error("exception decoding api data")
                }
                return response as? [[String: Any]]
            }
            let resource = RelatedDigitalNetwork.buildResource(endPoint: .geofence,
                                                         method: .get,
                                                         timeoutInterval: timeoutInterval,
                                                         requestBody: nil,
                                                         queryItems: queryItems,
                                                         headers: headers,
                                                         parse: responseParserGetList)
            sendGeofenceRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
        } else {
            let responseParserSendPush: (Data) -> String = { _ in return "" }
            let resource = RelatedDigitalNetwork.buildResource(endPoint: .geofence,
                                                         method: .get,
                                                         timeoutInterval: timeoutInterval,
                                                         requestBody: nil,
                                                         queryItems: queryItems,
                                                         headers: headers,
                                                         parse: responseParserSendPush)
            sendGeofencePushRequestHandler(resource: resource, completion: { _, error in completion(nil, error) })
        }
    }
    
    private class func sendGeofencePushRequestHandler(resource: RDResource<String>,
                                                      completion: @escaping (String?, RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { (result, _) in
            completion(result, nil)
        })
    }
    
    private class func sendGeofenceRequestHandler(resource: RDResource<[[String: Any]]>,
                                                  completion: @escaping ([[String: Any]]?, RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { (result, _) in
            completion(result, nil)
        })
    }
    
    // MARK: - InAppNotification
    
    // TO_DO: completion Any mi olmalı, yoksa AnyObject mi?
    class func sendInAppNotificationRequest(properties: [String: String],
                                            headers: [String: String],
                                            timeoutInterval: TimeInterval,
                                            completion: @escaping ([[String: Any]]?) -> Void) {
        
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }
        
        let responseParser: (Data) -> [[String: Any]]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding api data")
            }
            return response as? [[String: Any]]
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: .action,
                                                     method: .get,
                                                     timeoutInterval: timeoutInterval,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: headers,
                                                     parse: responseParser)
        
        sendInAppNotificationRequestHandler(resource: resource, completion: { result in completion(result) })
        
    }
    
    private class func sendInAppNotificationRequestHandler(resource: RDResource<[[String: Any]]>,
                                                           completion: @escaping ([[String: Any]]?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil)
        }, success: { (result, _) in
            completion(result)
        })
    }
    
    // MARK: - Mobile
    
    class func sendMobileRequest(properties: [String: String],
                                 headers: [String: String],
                                 timeoutInterval: TimeInterval,
                                 completion: @escaping ([String: Any]?, RelatedDigitalError?, String?) -> Void,
                                 guid: String? = nil) {
        
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }
        
        let responseParser: (Data) -> [String: Any]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding api data")
            }
            return response as? [String: Any]
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: .mobile,
                                                     method: .get,
                                                     timeoutInterval: timeoutInterval,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: headers,
                                                     parse: responseParser,
                                                     guid: guid)
        
        sendMobileRequestHandler(resource: resource,
                                 completion: { result, error, guid in completion(result, error, guid)})
        
    }
    
    private class func sendMobileRequestHandler(resource: RDResource<[String: Any]>,
                                                completion: @escaping ([String: Any]?,
                                                                       RelatedDigitalError?, String?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error, resource.guid)
        }, success: { (result, _) in
            completion(result, nil, resource.guid)
        })
    }
    
    class func sendPromotionCodeRequest(properties: [String: String],
                                        completion: @escaping ([String: Any]?, RelatedDigitalError?) -> Void) {
        
        let props = getDefaultQueryStringParameters().merging(properties) { (_, new) in new }
        
        var queryItems = [URLQueryItem]()
        for prop in props {
            queryItems.append(URLQueryItem(name: prop.key, value: prop.value))
        }
        
        let responseParser: (Data) -> [String: Any]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding api data")
            }
            return response as? [String: Any]
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: .promotion,
                                                     method: .get,
                                                     timeoutInterval: RelatedDigital.rdProfile.requestTimeoutInterval,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: [String: String](),
                                                     parse: responseParser)
        
        sendPromotionCodeRequestHandler(resource: resource,
                                        completion: { result, error in completion(result, error)})
        
    }
    
    private class func sendPromotionCodeRequestHandler(resource: RDResource<[String: Any]>,
                                                       completion: @escaping ([String: Any]?,
                                                                              RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { (result, _) in
            completion(result, nil)
        })
    }
    
    class func sendSubsJsonRequest(properties: [String: String]) {
        
        let props = properties.merging(getDefaultQueryStringParameters()) { (_, new) in new }
        
        var queryItems = [URLQueryItem]()
        for prop in props {
            queryItems.append(URLQueryItem(name: prop.key, value: prop.value))
        }
        
        let responseParser: (Data) -> String? = { data in
            return String(data: data, encoding: .utf8)
        }
        
        let resource  = RelatedDigitalNetwork.buildResource(endPoint: .subsjson,
                                                      method: .get,
                                                      timeoutInterval: RelatedDigital.rdProfile.requestTimeoutInterval,
                                                      requestBody: nil,
                                                      queryItems: queryItems,
                                                      headers: [String: String]() ,
                                                      parse: responseParser,
                                                      guid: nil)
        
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
        }, success: { (_, _) in
            print("Successfully sent!")
        })
        
    }
    
    class func sendRemoteConfigRequest(completion: @escaping ([String]?, RelatedDigitalError?) -> Void) {

        
        let responseParser: (Data) -> [String]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding remote config data")
            }
            return response as? [String]
        }
        
        var headers = [String: String]()
        if let userAgent = RelatedDigital.rdUser.userAgent {
            headers =  ["User-Agent": userAgent]
        }
        
        let resource = RelatedDigitalNetwork.buildResource(endPoint: .remote ,
                                                     method: .get,
                                                     timeoutInterval: RelatedDigital.rdProfile.requestTimeoutInterval,
                                                     headers: headers,
                                                     parse: responseParser)
        
        sendRemoteConfigRequestHandler(resource: resource, completion: { result, error in completion(result, error)})
        
    }
    
    private class func sendRemoteConfigRequestHandler(resource: RDResource<[String]>,
                                                      completion: @escaping ([String]?,
                                                                             RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { (result, _) in
            completion(result, nil)
        })
    }
    
    private class func getDefaultQueryStringParameters() -> [String: String] {
        
        var props = [String: String]()
        
        let profile = RelatedDigital.rdProfile
        let user = RelatedDigital.rdUser
        
        props[RDConstants.organizationIdKey] = profile.organizationId
        props[RDConstants.profileIdKey] = profile.profileId
        props[RDConstants.channelKey] = profile.channel
        props[RDConstants.mobileApplicationKey] = RDConstants.isTrue
        props[RDConstants.apiverKey] = RDConstants.ios
        
        props[RDConstants.cookieIdKey] = user.cookieId
        props[RDConstants.exvisitorIdKey] = user.exVisitorId
        props[RDConstants.mobileSdkVersion] = user.sdkVersion
        props[RDConstants.mobileAppVersion] = user.appVersion
        props[RDConstants.mobileIdKey] = user.identifierForAdvertising ?? ""
        props[RDConstants.nrvKey] = String(user.nrv)
        props[RDConstants.pvivKey] = String(user.pviv)
        props[RDConstants.tvcKey] = String(user.tvc)
        props[RDConstants.lvtKey] = user.lvt
        
        return props
    }
    
}
