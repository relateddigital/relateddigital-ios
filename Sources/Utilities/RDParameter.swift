//
//  RDParameter.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 23.11.2021.
//

import Foundation

class RDParameter {
    var key: String
    var storeKey: String
    var count: UInt8
    var relatedKeys: [String]?

    init(key: String, storeKey: String, count: UInt8, relatedKeys: [String]?) {
        self.key = key
        self.storeKey = storeKey
        self.count = count
        self.relatedKeys = relatedKeys
    }
}
