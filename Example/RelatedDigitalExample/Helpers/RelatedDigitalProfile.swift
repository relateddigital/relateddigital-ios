//
//  RelatedDigitalProfile.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation
import RelatedDigitalIOS

struct RelatedDigitalProfile: Codable {
    var organizationId = urlConstant.shared.organizationId
    var profileId = urlConstant.shared.profileId
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
