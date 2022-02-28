//
//  PushRequestProtocol.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

protocol PushRequestProtocol: PushCodable {
    var path: String { get }
    var method: String { get }
    var subdomain: String { get }
    var prodBaseUrl: String { get }
}
