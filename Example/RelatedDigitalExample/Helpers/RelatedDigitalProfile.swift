//
//  RelatedDigitalProfile.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation

struct RelatedDigitalProfile: Codable {
    var organizationId = "676D325830564761676D453D"
    var profileId = "356467332F6533766975593D"
    var dataSource = "visistore"
    var inAppNotificationsEnabled: Bool = true
    var channel = "IOS"
    var requestTimeoutInSeconds = 30
    var geofenceEnabled: Bool = true
    var maxGeofenceCount = 20
    var appAlias = "RDIOSExample"
    var appToken = ""
    var userKey = "userKey"
    var userEmail = "user@mail.com"
    var isIDFAEnabled = true

}
