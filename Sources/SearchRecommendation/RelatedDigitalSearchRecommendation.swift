//
//  VisilabsSearchRecommendation.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 9.02.2024.
//

import Foundation


class RelatedDigitalSearchRecommendation {
        
    
    func searchRecommend(relatedUser: RDUser,
                         properties: [String: String] = [:],
                         keyword: String = "",
                         searchType: String,
                         completion: @escaping ((_ response: RelatedDigitalSearchRecommendationResponse) -> Void)) {
        let relatedProfile = RelatedDigital.rdProfile
        
        var props = cleanProperties(properties)


        props[RDConstants.organizationIdKey] = relatedProfile.organizationId
        props[RDConstants.profileIdKey] = relatedProfile.profileId
        props[RDConstants.cookieIdKey] = relatedUser.cookieId
        props[RDConstants.exvisitorIdKey] = relatedUser.exVisitorId
        props[RDConstants.tokenIdKey] = relatedUser.tokenId
        props[RDConstants.appidKey] = relatedUser.appId
        props[RDConstants.apiverKey] = RDConstants.apiverValue
        props[RDConstants.channelKey] = RDConstants.ios
        props[RDConstants.sdkTypeKey] = RDConstants.sdkType
        props[RDConstants.utmCampaignKey] = relatedUser.utmCampaign
        props[RDConstants.utmMediumKey] = relatedUser.utmMedium
        props[RDConstants.utmSourceKey] = relatedUser.utmSource
        props[RDConstants.utmContentKey] = relatedUser.utmContent
        props[RDConstants.utmTermKey] = relatedUser.utmTerm
        
        props[RDConstants.nrvKey] = String(relatedUser.nrv)
        props[RDConstants.pvivKey] = String(relatedUser.pviv)
        props[RDConstants.tvcKey] = String(relatedUser.tvc)
        props[RDConstants.lvtKey] = relatedUser.lvt
        props[RDConstants.keyword] = keyword
        props[RDConstants.searchChannel] = searchType

        

        for (key, value) in RDPersistence.readTargetParameters() {
            if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                props[key] = value
            }
        }
        
        RDRequest.sendSearchRecommendationRequest(properties: props, headers: [String: String]()) { result in
            guard let result = result else {
                completion(RelatedDigitalSearchRecommendationResponse(responseDict: [String : Any]()))
                return
            }
            completion(RelatedDigitalSearchRecommendationResponse(responseDict: result))
        }
        
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
                && !propKey.isEqual(RDConstants.filterKey)
                && !propKey.isEqual(RDConstants.channelKey)
                && !propKey.isEqual(RDConstants.sdkTypeKey)
                && !propKey.isEqual(RDConstants.utmCampaignKey)
                && !propKey.isEqual(RDConstants.utmMediumKey)
                && !propKey.isEqual(RDConstants.utmSourceKey)
                && !propKey.isEqual(RDConstants.utmContentKey)
                && !propKey.isEqual(RDConstants.utmTermKey) {
                continue
            } else {
                props.removeValue(forKey: propKey)
            }
        }
        return props
    }
    
}
