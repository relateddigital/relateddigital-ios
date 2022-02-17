//
//  RDUser.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.02.2022.
//

import Foundation
import UIKit

struct RDUser: Codable {
    var cookieId: String?
    var exVisitorId: String?
    var tokenId: String?
    var appId: String?
    var visitData: String?
    var visitorData: String?
    var userAgent: String?
    var identifierForAdvertising: String?
    var sdkVersion: String?
    var lastEventTime: String?
    var nrv = 0
    var pviv = 0
    var tvc = 0
    var lvt: String?
    var appVersion: String?
}
