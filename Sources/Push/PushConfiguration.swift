//
//  PushConfiguration.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.02.2022.
//

import Foundation

public struct PushConfiguration {
    public var userProperties: [String: Any]?
    public var properties: PushProperties?
    public var firstTime: Int?
    public var osVersion: String?
    public var deviceType: String?
    public var osName: String?
    public var deviceName: String?
    public var token: String?
    public var local: String?
    public var identifierForVendor: String?
    public var appKey: String?
    public var appVersion: String?
    public var advertisingIdentifier: String?
    public var sdkVersion: String?
    public var carrier: String?
}
