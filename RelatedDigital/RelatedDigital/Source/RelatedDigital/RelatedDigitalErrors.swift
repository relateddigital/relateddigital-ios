//
//  RelatedDigitalErrors.swift
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

@objc
public class RelatedDigitalErrors : NSObject {
    @objc
    public class func parseError(_ message: String) -> Error {
        return NSError(domain: "com.relateddigital.parse_error", code: 1, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    @objc
    public class func error(_ message: String) -> Error {
        return NSError(domain: "com.relateddigital.error", code: 1, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
}
