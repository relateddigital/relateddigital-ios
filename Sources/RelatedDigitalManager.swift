//
//  RelatedDigitalManager.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

class RelatedDigitalManager {
    static let sharedInstance = RelatedDigitalManager()
    private var instance: RelatedDigitalInstance?

    func initialize(organizationId: String, profileId: String, dataSource: String) -> RelatedDigitalInstance {
        let instance = RelatedDigitalInstance(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
        self.instance = instance
        return instance
    }

    func getInstance() -> RelatedDigitalInstance? {
        return instance
    }
}

