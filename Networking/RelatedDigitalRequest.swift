//
//  RelatedDigitalRequest.swift
//  RelatedDigitalIOS
//
//  Created by Umut Can ALPARSLAN on 21.10.2021.
//

import Foundation

class RelatedDigitalRequest {
    // MARK: - RECOMMENDATION

    // TO_DO: completion Any mi olmalı, yoksa AnyObject mi?
    class func sendRecommendationRequest(properties: [String: String],
                                         headers: [String: String],
                                         timeoutInterval: TimeInterval,
                                         completion: @escaping ([Any]?, RelatedDigitalError?) -> Void) {
        /*
         if RelatedDigitalRemoteConfig.isBlocked == true {
             RelatedDigitalLogger.info("Too much server load!")
             return
         }
          */

        var queryItems = [URLQueryItem]()
        for property in properties {
            queryItems.append(URLQueryItem(name: property.key, value: property.value))
        }

        let responseParser: (Data) -> [Any]? = { data in
            var response: Any?
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                RelatedDigitalLogger.error("exception decoding api data")
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

    private class func sendRecommendationRequestHandler(resource: RelatedDigitalResource<[Any]>,
                                                        completion: @escaping ([Any]?, RelatedDigitalError?) -> Void) {
        RelatedDigitalNetwork.apiRequest(resource: resource,
                                   failure: { error, _, _ in
                                       RelatedDigitalLogger.error("API request to \(resource.endPoint) has failed with error \(error)")
                                       completion(nil, error)
                                   }, success: { result, _ in
                                       completion(result, nil)
                                   })
    }
}
