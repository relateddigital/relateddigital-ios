//
//  RelatedDigitalDictionary.swift
//  RelatedDigitalIOS
//
//  Created by Umut Can ALPARSLAN on 21.10.2021.
//

import Foundation

extension Optional where Wrapped == String {
    var isNilOrWhiteSpace: Bool {
        return self?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
    }
}
