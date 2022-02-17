//
//  VisilabsRecommendation.swift
//  VisilabsIOS
//
//  Created by Egemen on 29.06.2020.
//

import Foundation

class RelatedDigitalRecommendation {
    let rdProfile: RDProfile

    init(rdProfile: RDProfile) {
        self.rdProfile = rdProfile
    }

    func recommend(zoneId: String,
                   productCode: String?,
                   rdUser: RDUser,
                   channel: String,
                   properties: [String: String] = [:],
                   filters: [RelatedDigitalRecommendationFilter] = [],
                   completion: @escaping ((_ response: RelatedDigitalRecommendationResponse) -> Void)) {

        var props = cleanProperties(properties)

        if filters.count > 0 {
            props[RDConstants.filterKey] = getFiltersQueryStringValue(filters)
        }

        props[RDConstants.organizationIdKey] = self.rdProfile.organizationId
        props[RDConstants.profileIdKey] = self.rdProfile.profileId
        props[RDConstants.cookieIdKey] = rdUser.cookieId
        props[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RDConstants.tokenIdKey] = rdUser.tokenId
        props[RDConstants.appidKey] = rdUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        
        props[RDConstants.nrvKey] = String(rdUser.nrv)
        props[RDConstants.pvivKey] = String(rdUser.pviv)
        props[RDConstants.tvcKey] = String(rdUser.tvc)
        props[RDConstants.lvtKey] = rdUser.lvt

        if zoneId.count > 0 {
            props[RDConstants.zoneIdKey] = zoneId
        }
        if !productCode.isNilOrWhiteSpace {
            props[RDConstants.bodyKey] = productCode
        }

        for (key, value) in RDPersistence.readTargetParameters() {
            if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                props[key] = value
            }
        }

        RDRequest.sendRecommendationRequest(properties: props, headers: [String: String](), completion: { (results: [Any]?, error: RDError?) in
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
            RDLogger.warn("exception serializing recommendation filters: \(error.localizedDescription)")
        }
        return queryStringValue
    }

    private func cleanProperties(_ properties: [String: String]) -> [String: String] {
        var props = properties
        for propKey in props.keys {
            if !propKey.isEqual(RDConstants.organizationIdKey)
                && !propKey.isEqual(RDConstants.profileIdKey)
                && !propKey.isEqual(RDConstants.exvisitorIdKey)
                && !propKey.isEqual(RDConstants.cookieIdKey)
                && !propKey.isEqual(RDConstants.zoneIdKey)
                && !propKey.isEqual(RDConstants.bodyKey)
                && !propKey.isEqual(RDConstants.tokenIdKey)
                && !propKey.isEqual(RDConstants.appidKey)
                && !propKey.isEqual(RDConstants.apiverKey)
                && !propKey.isEqual(RDConstants.filterKey) {
                continue
            } else {
                props.removeValue(forKey: propKey)
            }
        }
        return props
    }

}
