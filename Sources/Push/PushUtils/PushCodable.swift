//
//  PushCodable.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 10.02.2022.
//

import UIKit

public protocol PushCodable: Codable {}
public extension PushCodable {
    var encoded: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
