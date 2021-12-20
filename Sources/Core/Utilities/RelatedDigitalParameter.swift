//
//  RelatedDigitalParameter.swift
//  RelatedDigitalIOS
//
//  Created by Umut Can ALPARSLAN on 21.10.2021.
//

import Foundation

class RelatedDigitalParameter {
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

public class urlConstant {
    static var shared = urlConstant()
    var urlPrefix = "s.visilabs.net"
    var securityTag = "https"
    var organizationId = "676D325830564761676D453D"
    var profileId = "356467332F6533766975593D"
    
    func setTest() {
        urlPrefix = "tests.visilabs.net"
        securityTag = "http"
    }
}
