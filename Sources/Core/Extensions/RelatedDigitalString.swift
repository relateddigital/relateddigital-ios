//
//  RelatedDigitalString.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 12.07.2021.
//

import Foundation

extension String {
    static private let dateFormatter = DateFormatter()
    func parseDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        String.dateFormatter.dateFormat = format
        return String.dateFormatter.date(from: self)
    }
    
    var isEmptyOrWhitespace: Bool {
        return self.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
}
