//
//  RelatedDigitalDate.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

extension Date {
    static private let dateFormatter = DateFormatter()
    func format(_ format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        Date.dateFormatter.dateFormat = format
        return Date.dateFormatter.string(from: self)
    }
}
