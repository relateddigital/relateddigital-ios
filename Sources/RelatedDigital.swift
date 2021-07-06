//
//  RelatedDigital.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

public class RelatedDigital {
    public class func callAPI() -> RelatedDigitalInstance {
        if let instance = RelatedDigitalManager.sharedInstance.getInstance() {
            return instance
        } else {
            assert(false, "You have to call createAPI before calling the callAPI.")
            return RelatedDigital.createAPI(organizationId: "", profileId: "", dataSource: "")
        }
    }

    @discardableResult
    public class func createAPI(organizationId: String, profileId: String, dataSource: String) -> RelatedDigitalInstance {
        RelatedDigitalManager.sharedInstance.initialize(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
    }
}
