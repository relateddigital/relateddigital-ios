//
//  RDError.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import Foundation

public enum RDConfigError: Error, LocalizedError {
    case missingPlist
    case missingConfiguration(key: String)
    case initializationFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .missingPlist:
            return "RelatedDigital-Info.plist file not found in the main bundle."
        case .missingConfiguration(let key):
            return "Missing required configuration key: \(key)"
        case .initializationFailed(let reason):
            return "SDK Initialization failed: \(reason)"
        }
    }
}
