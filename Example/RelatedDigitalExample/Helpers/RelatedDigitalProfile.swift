//
//  RelatedDigitalProfile.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation
import RelatedDigitalIOS

struct RelatedDigitalProfile: Codable {
    var organizationId = UrlConstant.shared.organizationId
    var profileId = UrlConstant.shared.profileId
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
    var testUrlIsActive = UrlConstant.shared.getTestWithLocalData()

}
