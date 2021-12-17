//
//  VisilabsProfile.swift
//  Pods-RelatedDigitalExample
//
//  Created by Orhun Akmil on 17.12.2021.
//

import Foundation


struct VisilabsProfile: Codable {
    var organizationId: String
    var profileId: String
    var dataSource: String
    var channel: String
    var requestTimeoutInSeconds: Int
    var geofenceEnabled: Bool
    var inAppNotificationsEnabled: Bool
    var maxGeofenceCount: Int
    var isIDFAEnabled: Bool
    var requestTimeoutInterval: TimeInterval {
        return TimeInterval(requestTimeoutInSeconds)
    }

    var useInsecureProtocol = false
}
