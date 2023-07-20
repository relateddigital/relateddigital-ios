//
//  RDProfile.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.02.2022.
//

import Foundation

public struct RDProfile: Codable {
    public var organizationId: String
    public var profileId: String
    public var dataSource: String
    public var channel: String = "IOS"
    public var requestTimeoutInSeconds: Int = 30
    public var geofenceEnabled: Bool = false
    public var askLocationPermissionAtStart: Bool = true
    public var inAppNotificationsEnabled: Bool = false
    public var maxGeofenceCount: Int = 20
    public var isIDFAEnabled: Bool = false
    public var useInsecureProtocol = false
    public var isPushNotificationEnabled: Bool = false
    public var appAlias: String?
    public var appGroupsKey: String?
    
    
    var requestTimeoutInterval: TimeInterval {
        let ti = requestTimeoutInSeconds < 5 ? TimeInterval(30) : TimeInterval(requestTimeoutInSeconds)
        return ti
    }
    
}
