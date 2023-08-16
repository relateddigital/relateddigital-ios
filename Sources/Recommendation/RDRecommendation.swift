//
// RDRecommendation.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

import Foundation

class RDRecommendation {
    func recommend(zoneId: String, productCode: String?, rdUser: RDUser, properties: Properties = [:], filters: [RDRecommendationFilter] = [], completion: @escaping ((_ response: RDRecommendationResponse) -> Void)) {
        var props = cleanProperties(properties)

        if filters.count > 0 {
            props[RDConstants.filterKey] = getFiltersQueryStringValue(filters)
        }

        props[RDConstants.organizationIdKey] = RelatedDigital.rdProfile.organizationId
        props[RDConstants.profileIdKey] = RelatedDigital.rdProfile.profileId
        props[RDConstants.cookieIdKey] = rdUser.cookieId
        props[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
        props[RDConstants.tokenIdKey] = rdUser.tokenId
        props[RDConstants.appidKey] = rdUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        props[RDConstants.channelKey] = RelatedDigital.rdProfile.channel
        props[RDConstants.utmCampaignKey] = rdUser.utmCampaign
        props[RDConstants.utmContentKey] = rdUser.utmContent
        props[RDConstants.utmMediumKey] = rdUser.utmMedium
        props[RDConstants.utmSourceKey] = rdUser.utmSource
        props[RDConstants.utmTermKey] = rdUser.utmTerm
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

        RDRequest.sendRecommendationRequest(properties: props, completion: { (results: [Any]?, error: RDError?) in
            var products = [RDProduct]()
            if error != nil {
                completion(RDRecommendationResponse(products: [RDProduct](), error: error))
            } else {
                var widgetTitle = ""
                var counter = 0
                for result in results! {
                    if let jsonObject = result as? [String: Any?], let product = RDProduct(JSONObject: jsonObject) {
                        products.append(product)
                        if counter == 0 {
                            widgetTitle = jsonObject["wdt"] as? String ?? ""
                        }
                        counter = counter + 1
                    }
                }
                completion(RDRecommendationResponse(products: products, widgetTitle: widgetTitle, error: nil))
            }
        })
    }

    private func getFiltersQueryStringValue(_ filters: [RDRecommendationFilter]) -> String? {
        var queryStringValue: String?
        var abbrevatedFilters: [Properties] = []
        for filter in filters where filter.value.count > 0 {
            var abbrevatedFilter = Properties()
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

    private func cleanProperties(_ properties: Properties) -> Properties {
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
                && !propKey.isEqual(RDConstants.filterKey)
                && !propKey.isEqual(RDConstants.utmCampaignKey)
                && !propKey.isEqual(RDConstants.utmContentKey)
                && !propKey.isEqual(RDConstants.utmMediumKey)
                && !propKey.isEqual(RDConstants.utmSourceKey)
                && !propKey.isEqual(RDConstants.utmTermKey) {
                continue
            } else {
                props.removeValue(forKey: propKey)
            }
        }
        return props
    }
}
