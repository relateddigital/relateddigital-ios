//
//  RDUser.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 17.02.2022.
//

import Foundation
import UIKit

public struct RDUser: Codable {
    public var cookieId: String?
    public var exVisitorId: String?
    public var tokenId: String?
    public var appId: String?
    public var visitData: String?
    public var visitorData: String?
    public var userAgent: String?
    public var identifierForAdvertising: String?
    public var sdkVersion: String?
    public var lastEventTime: String?
    public var nrv = 0
    public var pviv = 0
    public var tvc = 0
    public var lvt: String?
    public var appVersion: String?
}
