//
//  RelatedDigitalUser.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

typealias Queue = [[String: String]]

struct RelatedDigitalUser: Codable {
    var cookieId: String?
    var exVisitorId: String?
    var tokenId: String?
    var appId: String?
    var visitData: String?
    var visitorData: String?
    var userAgent: String?
    var identifierForAdvertising: String?
    var lastEventTime: String?
    var nrv = 0
    var pviv = 0
    var tvc = 0
    var lvt: String?
    var appVersion: String?
    var sdkVersion: String?
}
