//
//  VisilabsExtensions.swift
//  VisilabsIOS
//
//  Created by Egemen on 14.04.2020.
//

import UIKit

/**
Extensions to standard primitive and collections classes to support easier json
parsing. Internally, it uses the system provided 'NSJSONSerialization' class to perform
the actual json serialization/deserialization
*/

extension Data {
    func objectFromJsonData() -> Any? {
        return try? JSONSerialization.jsonObject(with: self as Data, options: .allowFragments)
    }
}

/**
JSON convenient categories on NSString
*/
extension String {

    // TO_DO:self as nsstring'e gerek var mı?
    func stringBetweenString(start: String?, end: String?) -> String? {
        let startRange = (self as NSString).range(of: start ?? "")
        if startRange.location != NSNotFound {
            var targetRange: NSRange = NSRange()
            targetRange.location = startRange.location + startRange.length
            targetRange.length = count - targetRange.location
            let endRange = (self as NSString).range(of: end ?? "", options: [], range: targetRange)
            if endRange.location != NSNotFound {
                targetRange.length = endRange.location - targetRange.location
                return (self as NSString).substring(with: targetRange)
            }
        }
        return nil
    }

    func contains(_ string: String, options: String.CompareOptions) -> Bool {
        let rng = (self as NSString).range(of: string, options: options)
        return rng.location != NSNotFound
    }

    func contains(_ string: String) -> Bool {
        return contains(string, options: [])
    }

    // TO_DO:bunu kontrol et: objective-c'de pointer'lı bir şeyler kullanıyorduk
    func urlEncode() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }

    func urlDecode() -> String {
        return self.removingPercentEncoding ?? ""
    }

    func convertJsonStringToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }

    /**
    Returns a Foundation object from the given JSON string.
     
    - returns: A Foundation object from the JSON string, or nil if an error occurs.
    */

    func objectFromJsonString() -> Any? {
        let data = self.data(using: .utf8)
        return data?.objectFromJsonData()
    }

    func getUrlWithoutExtension() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().absoluteString
    }

    func getUrlExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}

/**
JSON convenient extensions on NSArray
*/

extension Array {

    /**
    Returns JSON string from the given array.
    
    - returns: returns  a JSON String, or nil if an internal error occurs. The resulting data is an encoded in UTF-8.
    */

    func jsonString() -> String? {
        let data = jsonData()
        if data != nil {
            if let data = data {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
        return nil
    }

    /**
    Returns JSON data from the given array.
    
    - returns: returns a JSON data, or nil if an internal error occurs. The resulting data is an encoded in UTF-8.
    */

    func jsonData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}

/**
JSON convenient extensions on Dictionary
*/

extension Dictionary {

    /**
    Returns JSON string from the given dictionary.
    
    - returns: returns a JSON String, or nil if an internal error occurs. The resulting data is an encoded in UTF-8.
    */

    func jsonString() -> String? {
        let data = jsonData()
        if data != nil {
            if let data = data {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
        return nil
    }

    /**
    Returns JSON data from the given dictionary.
    
    - returns:returns a JSON data, or nil if an internal error occurs. The resulting data is an encoded in UTF-8.
    */

    func jsonData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}

extension Optional where Wrapped == String {

    var isNilOrWhiteSpace: Bool {
        return self?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
    }

}

extension Optional where Wrapped == [String] {
    mutating func mergeStringArray(_ newArray: [String]) {
        self = self ?? [String]()
        for newArrayElement in newArray {
            if !self!.contains(newArrayElement) {
                self!.append(newArrayElement)
            }
        }
    }
}

extension Int {
    var toFloat: CGFloat {
        return CGFloat(self)
    }
}

extension UIColor {
    
    convenience init?(hex: String?, alpha: CGFloat = 1.0) {
        
        guard let hexString = hex else {
            return nil
        }
        var cString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") { cString.removeFirst() }
        
        if cString.count != 6 && cString.count != 8 {
            return nil
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        if cString.count == 6 {
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                      alpha: alpha)
        } else {
            let alpha = CGFloat((rgbValue & 0xff000000) >> 24) / 255
            let red = CGFloat((rgbValue & 0x00ff0000) >> 16) / 255
            let green = CGFloat((rgbValue & 0x0000ff00) >> 8) / 255
            let blue = CGFloat(rgbValue & 0x000000ff) / 255
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    convenience init?(rgbaString: String) {
        let rgbaNumbersString = rgbaString.replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let rgbaParts = rgbaNumbersString.split(separator: ",")
        if rgbaParts.count == 4 {
            guard let red = Float(rgbaParts[0]),
                  let green = Float(rgbaParts[1]),
                  let blue = Float(rgbaParts[2]),
                  let alpha = Float(rgbaParts[3]) else {
                      return nil
                  }
            self.init(red: CGFloat(red / 255.0),
                      green: CGFloat(green / 255.0),
                      blue: CGFloat(blue / 255.0),
                      alpha: CGFloat(alpha))
            
        } else {
            return nil
        }
    }
    
    /**
     Add two colors together
     */
    func add(overlay: UIColor) -> UIColor {
        var bgR: CGFloat = 0
        var bgG: CGFloat = 0
        var bgB: CGFloat = 0
        var bgA: CGFloat = 0
        
        var fgR: CGFloat = 0
        var fgG: CGFloat = 0
        var fgB: CGFloat = 0
        var fgA: CGFloat = 0
        
        self.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        overlay.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        
        let red = fgA * fgR + (1 - fgA) * bgR
        let green = fgA * fgG + (1 - fgA) * bgG
        let blue = fgA * fgB + (1 - fgA) * bgB
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
