//
//  PushRetentionRequest.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.02.2022.
//

import Foundation

struct PushRetentionRequest: PushCodable, PushRequestProtocol {
    internal var path = "retention"
    internal var method = "POST"
    internal var subdomain = "pushr"
    internal var prodBaseUrl = ".euromsg.com"

    var key: String
    var token: String
    var status: String
    var pushId: String
    var emPushSp: String
    
    enum CodingKeys: String, CodingKey {
        case key = "key"
        case token = "token"
        case status = "status"
        case pushId = "pushId"
        case emPushSp = "emPushSp"
    }
}
