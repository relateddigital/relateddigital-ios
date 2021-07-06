//
//  RelatedDigitalProfile.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

struct RelatedDigitalProfile: Codable {
    var organizationId: String
    var profileId: String
    var dataSource: String
    var channel = "IOS"
    var requestTimeoutInSeconds = 30
    var geofenceEnabled = false
    var inAppNotificationsEnabled = false
    var maxGeofenceCount = 20
    var requestTimeoutInterval: TimeInterval {
        return TimeInterval(requestTimeoutInSeconds)
    }
    var useInsecureProtocol = false
    var isIDFAEnabled = false
    var pushNotificationsEnabled = false
    var appAlias = ""
}

