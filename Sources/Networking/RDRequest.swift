//
//  RDRequest.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 16.08.2021.
//

import Foundation

class RDRequest {
    // MARK: - EVENT

    class func sendEventRequest(rdEndpoint: RDEndpoint, properties: Properties, headers: Properties, completion: @escaping (Properties?) -> Void) {
        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }

        let resource = RDNetwork.buildResource(endPoint: rdEndpoint, method: .get, queryItems: queryItems, headers: headers, parse: { _ in true })
        sendEventRequestHandler(resource: resource, completion: { success in completion(success) })
    }

    private class func sendEventRequestHandler(resource: RDResource<Bool>, completion: @escaping (Properties?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, response in

            var requestUrl = RDBasePath.getEndpoint(rdEndpoint: resource.endPoint)
            if let httpResponse = response as? HTTPURLResponse {
                if let url = httpResponse.url {
                    requestUrl = url.absoluteString
                }
            }
            RDLogger.error("API request to \(requestUrl) has failed with error \(error)")
            completion(nil)
        }, success: { _, response in

            if let httpResponse = response as? HTTPURLResponse, let url = httpResponse.url {
                RDLogger.info("\(url.absoluteString) request sent successfully")
                let cookies = getCookies(url)
                completion(cookies)
            } else {
                let end = RDBasePath.getEndpoint(rdEndpoint: resource.endPoint)
                RDLogger.error("\(end) can not convert to HTTPURLResponse")
                completion(nil)
            }

        })
    }

    private class func getCookies(_ url: URL) -> Properties {
        var cookieKeyValues = Properties()
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
    class func sendRecommendationRequest(properties: Properties, completion: @escaping ([Any]?, RDError?) -> Void) {
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

        let resource = RDNetwork.buildResource(endPoint: .target, method: .get, queryItems: queryItems, headers: [:], parse: responseParser)

        sendRecommendationRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendRecommendationRequestHandler(resource: RDResource<[Any]>, completion: @escaping ([Any]?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }
    
    
    
    // MARK: - SEARCHRECOMMENDATION
    //sendSearchRecommendationRequest
    //sendSearchRecommendationRequestHandler
    
    
    class func sendSearchRecommendationRequest(properties: [String: String],
                                            headers: [String: String],
                                            completion: @escaping ([String: Any]?) -> Void) {
        
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
        
        let resource = RDNetwork.buildResource(endPoint: .search,
                                                     method: .get,
                                                     requestBody: nil,
                                                     queryItems: queryItems,
                                                     headers: headers,
                                                     parse: responseParser)
        
        sendSearchRecommendationRequestHandler(resource: resource, completion: { result in completion(result) })
        
    }
    
    private class func sendSearchRecommendationRequestHandler(resource: RDResource<[String: Any]>, completion: @escaping ([String: Any]?) -> Void) {
        RDNetwork.apiRequest(resource: resource,
                                   failure: { (error, _, _) in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil)
        }, success: { (result, _) in
            completion(result)
        })
    }

    // MARK: - TARGETING ACTIONS

    // MARK: - Geofence

    class func sendGeofenceRequest(properties: Properties, headers: Properties = Properties(), completion: @escaping ([[String: Any]]?, RDError?) -> Void) {
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
            let resource = RDNetwork.buildResource(endPoint: .geofence, method: .get, queryItems: queryItems, headers: headers, parse: responseParserGetList)
            sendGeofenceRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
        } else {
            let responseParserSendPush: (Data) -> String = { _ in "" }
            let resource = RDNetwork.buildResource(endPoint: .geofence, method: .get, queryItems: queryItems, headers: headers, parse: responseParserSendPush)
            sendGeofencePushRequestHandler(resource: resource, completion: { _, error in completion(nil, error) })
        }
    }

    private class func sendGeofencePushRequestHandler(resource: RDResource<String>,
                                                      completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    private class func sendGeofenceRequestHandler(resource: RDResource<[[String: Any]]>, completion: @escaping ([[String: Any]]?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    // MARK: - InAppNotification

    // TO_DO: completion Any mi olmalı, yoksa AnyObject mi?
    class func sendInAppNotificationRequest(properties: Properties, headers: Properties, completion: @escaping ([[String: Any]]?) -> Void) {
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

        let resource = RDNetwork.buildResource(endPoint: .action, method: .get, queryItems: queryItems, headers: headers, parse: responseParser)

        sendInAppNotificationRequestHandler(resource: resource, completion: { result in completion(result) })
    }

    private class func sendInAppNotificationRequestHandler(resource: RDResource<[[String: Any]]>, completion: @escaping ([[String: Any]]?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil)
        }, success: { result, _ in
            completion(result)
        })
    }

    // MARK: - Mobile

    class func sendSpinToWinScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .spinToWinJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendSpinToWinScriptRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendSpinToWinScriptRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendGiftCatchScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .giftCatchJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendGiftCatchScriptRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendGiftCatchScriptRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendFindToWinScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .findToWinJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendFindToWinScriptRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    class func sendGiftBoxScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .giftBoxJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendGiftBoxRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendGiftBoxRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendChooseFavoriteScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .chooseFavoriteJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendChooseFavoriteRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendChooseFavoriteRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendJackpotScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .jackpotJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendJackpotRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendJackpotRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }
    
    class func sendClawMachineScriptRequest(completion: @escaping (String?, RDError?) -> Void) {
        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }
        let resource = RDNetwork.buildResource(endPoint: .clawMachineJs, method: .get, queryItems: [], headers: [:], parse: responseParser, guid: nil)
        sendClowMachineRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendClowMachineRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    private class func sendFindToWinScriptRequestHandler(resource: RDResource<String>, completion: @escaping (String?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendMobileRequest(properties: Properties, headers: Properties, completion: @escaping ([String: Any]?, RDError?, String?) -> Void, guid: String? = nil) {
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

        let resource = RDNetwork.buildResource(endPoint: .mobile, method: .get, queryItems: queryItems, headers: headers, parse: responseParser, guid: guid)

        sendMobileRequestHandler(resource: resource, completion: { result, error, guid in completion(result, error, guid) })
    }

    private class func sendMobileRequestHandler(resource: RDResource<[String: Any]>, completion: @escaping ([String: Any]?, RDError?, String?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error, resource.guid)
        }, success: { result, _ in
            completion(result, nil, resource.guid)
        })
    }

    class func sendPromotionCodeRequest(properties: Properties, completion: @escaping ([String: Any]?, RDError?) -> Void) {
        let props = getDefaultQueryStringParameters().merging(properties) { _, new in new }

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

        let resource = RDNetwork.buildResource(endPoint: .promotion, method: .get, requestBody: nil, queryItems: queryItems, headers: Properties(), parse: responseParser)

        sendPromotionCodeRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendPromotionCodeRequestHandler(resource: RDResource<[String: Any]>, completion: @escaping ([String: Any]?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    class func sendSubsJsonRequest(properties: Properties) {
        let props = properties.merging(getDefaultQueryStringParameters()) { _, new in new }

        var queryItems = [URLQueryItem]()
        for prop in props {
            queryItems.append(URLQueryItem(name: prop.key, value: prop.value))
        }

        let responseParser: (Data) -> String? = { data in
            String(data: data, encoding: .utf8)
        }

        let resource = RDNetwork.buildResource(endPoint: .subsjson, method: .get, queryItems: queryItems, headers: Properties(), parse: responseParser)

        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
        }, success: { _, _ in
            print("Successfully sent!")
        })
    }
    
    class func fetchLogConfig(completion: @escaping (LogConfig?) -> Void) {
            // Endpoint URL'sini alırken hata kontrolü yapalım
        let urlString = RDBasePath.getEndpoint(rdEndpoint: .logConfig)
        
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
                RDLogger.error("Invalid or undefined log config endpoint URL.")
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // Gerekirse timeout gibi diğer ayarları ekleyebilirsiniz.
            // request.timeoutInterval = RelatedDigital.rdProfile.requestTimeoutInterval // Eğer varsa

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    RDLogger.error("Log config fetch error: \(error.localizedDescription)")
                    completion(nil) // Hata durumunda varsayılan davranış (loglama yapılabilir veya yapılmayabilir)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    RDLogger.error("Invalid HTTP response for log config: \(String(describing: response))")
                    completion(nil)
                    return
                }

                guard let data = data else {
                    RDLogger.error("No data received for log config.")
                    completion(nil)
                    return
                }

                do {
                    let logConfig = try JSONDecoder().decode(LogConfig.self, from: data)
                     RDLogger.info("Log config fetched successfully: \(logConfig)")
                    completion(logConfig)
                } catch {
                    RDLogger.error("Failed to decode log config: \(error.localizedDescription)")
                    completion(nil)
                }
            }.resume()
        }
    
    

    class func sendRemoteConfigRequest(completion: @escaping ([String]?, RDError?) -> Void) {
        let responseParser: (Data) -> [String]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RDLogger.error("exception decoding remote config data")
            }
            return response as? [String]
        }

        var headers = Properties()
        if let userAgent = RelatedDigital.rdUser.userAgent {
            headers = ["User-Agent": userAgent]
        }

        let resource = RDNetwork.buildResource(endPoint: .remote, method: .get, headers: headers, parse: responseParser)
        sendRemoteConfigRequestHandler(resource: resource, completion: { result, error in completion(result, error) })
    }

    private class func sendRemoteConfigRequestHandler(resource: RDResource<[String]>, completion: @escaping ([String]?, RDError?) -> Void) {
        RDNetwork.apiRequest(resource: resource, failure: { error, _, _ in
            RDLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
            completion(nil, error)
        }, success: { result, _ in
            completion(result, nil)
        })
    }

    private class func getDefaultQueryStringParameters() -> Properties {
        var props = Properties()
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
        props[RDConstants.mobileSdkType] = user.sdkType
        props[RDConstants.mobileAppVersion] = user.appVersion
        props[RDConstants.utmCampaignKey] = user.utmCampaign
        props[RDConstants.utmSourceKey] = user.utmSource
        props[RDConstants.utmMediumKey] = user.utmMedium
        props[RDConstants.utmContentKey] = user.utmContent
        props[RDConstants.utmTermKey] = user.utmTerm
        props[RDConstants.mobileIdKey] = user.identifierForAdvertising ?? ""
        props[RDConstants.nrvKey] = String(user.nrv)
        props[RDConstants.pvivKey] = String(user.pviv)
        props[RDConstants.tvcKey] = String(user.tvc)
        props[RDConstants.lvtKey] = user.lvt
        props[RDConstants.isPushUser] = user.isPushUser
        props[RDConstants.pushTime] = user.pushTime
        return props
    }
}
