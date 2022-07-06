//
//  RDProfile.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.02.2022.
//

import Foundation

struct RDProfile: Codable {
    var organizationId: String
    var profileId: String
    var dataSource: String
    var channel: String = "IOS"
    var requestTimeoutInSeconds: Int = 30
    var geofenceEnabled: Bool = false
    var askLocationPermmissionAtStart: Bool = true
    var inAppNotificationsEnabled: Bool = false
    var maxGeofenceCount: Int = 20
    var isIDFAEnabled: Bool = false
    var useInsecureProtocol = false
    var isPushNotificationEnabled: Bool = false
    var appAlias: String?
    var appGroupsKey: String?
    
    
    var requestTimeoutInterval: TimeInterval {
        let ti = requestTimeoutInSeconds < 5 ? TimeInterval(30) : TimeInterval(requestTimeoutInSeconds)
        return ti
    }
    
}
