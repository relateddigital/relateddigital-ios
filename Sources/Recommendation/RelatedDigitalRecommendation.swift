//
//  VisilabsRecommendation.swift
//  VisilabsIOS
//
//  Created by Egemen on 29.06.2020.
//

import Foundation

class RelatedDigitalRecommendation {
    let rdProfile: RelatedDigitalProfile

    init(rdProfile: RelatedDigitalProfile) {
        self.rdProfile = rdProfile
    }

    func recommend(zoneId: String,
                   productCode: String?,
                   rdUser: RelatedDigitalUser,
                   channel: String,
                   properties: [String: String] = [:],
                   filters: [RelatedDigitalRecommendationFilter] = [],
                   completion: @escaping ((_ response: RelatedDigitalRecommendationResponse) -> Void)) {

        var props = cleanProperties(properties)

        if filters.count > 0 {
            props[RelatedDigitalConstants.filterKey] = getFiltersQueryStringValue(filters)
        }

        props[RelatedDigitalConstants.organizationIdKey] = self.rdProfile.organizationId
        props[RelatedDigitalConstants.profileIdKey] = self.rdProfile.profileId
        props[RelatedDigitalConstants.cookieIdKey] = rdUser.cookieId
        props[RelatedDigitalConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RelatedDigitalConstants.tokenIdKey] = rdUser.tokenId
        props[RelatedDigitalConstants.appidKey] = rdUser.appId
        props[RelatedDigitalConstants.apiverKey] = RelatedDigitalConstants.apiverValue
        
        props[RelatedDigitalConstants.nrvKey] = String(rdUser.nrv)
        props[RelatedDigitalConstants.pvivKey] = String(rdUser.pviv)
        props[RelatedDigitalConstants.tvcKey] = String(rdUser.tvc)
        props[RelatedDigitalConstants.lvtKey] = rdUser.lvt

        if zoneId.count > 0 {
            props[RelatedDigitalConstants.zoneIdKey] = zoneId
        }
        if !productCode.isNilOrWhiteSpace {
            props[RelatedDigitalConstants.bodyKey] = productCode
        }

        for (key, value) in RelatedDigitalPersistence.readTargetParameters() {
            if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                props[key] = value
            }
        }

        RelatedDigitalRequest.sendRecommendationRequest(properties: props,
                                                  headers: [String: String](),
                                                  timeoutInterval: rdProfile.requestTimeoutInterval,
                                                  completion: { (results: [Any]?, error: RelatedDigitalError?) in
            var products = [RelatedDigitalProduct]()
            if error != nil {
                completion(RelatedDigitalRecommendationResponse(products: [RelatedDigitalProduct](), error: error))
            } else {
                var widgetTitle = ""
                var counter = 0
                for result in results! {
                    if let jsonObject = result as? [String: Any?], let product = RelatedDigitalProduct(JSONObject: jsonObject) {
                        products.append(product)
                        if counter == 0 {
                            widgetTitle = jsonObject["wdt"] as? String ?? ""
                        }
                        counter = counter + 1
                    }
                }
                completion(RelatedDigitalRecommendationResponse(products: products, widgetTitle: widgetTitle, error: nil))
            }
        })
    }

    private func getFiltersQueryStringValue(_ filters: [RelatedDigitalRecommendationFilter]) -> String? {
        var queryStringValue: String?
        var abbrevatedFilters: [[String: String]] = []
        for filter in filters where filter.value.count > 0 {
            var abbrevatedFilter = [String: String]()
            abbrevatedFilter["attr"] = filter.attribute.rawValue
            abbrevatedFilter["ft"] = String(filter.filterType.rawValue)
            abbrevatedFilter["fv"] = filter.value
            abbrevatedFilters.append(abbrevatedFilter)
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: abbrevatedFilters, options: [])
            queryStringValue = String(data: jsonData, encoding: .utf8)
        } catch {
            RelatedDigitalLogger.warn("exception serializing recommendation filters: \(error.localizedDescription)")
        }
        return queryStringValue
    }

    private func cleanProperties(_ properties: [String: String]) -> [String: String] {
        var props = properties
        for propKey in props.keys {
            if !propKey.isEqual(RelatedDigitalConstants.organizationIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.profileIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.exvisitorIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.cookieIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.zoneIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.bodyKey)
                && !propKey.isEqual(RelatedDigitalConstants.tokenIdKey)
                && !propKey.isEqual(RelatedDigitalConstants.appidKey)
                && !propKey.isEqual(RelatedDigitalConstants.apiverKey)
                && !propKey.isEqual(RelatedDigitalConstants.filterKey) {
                continue
            } else {
                props.removeValue(forKey: propKey)
            }
        }
        return props
    }

}
