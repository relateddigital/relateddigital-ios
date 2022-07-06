//
// RDCLAuthorizationStatus.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

import Foundation
import CoreLocation

public enum RDCLAuthorizationStatus: Int32 {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorizedAlways = 3
    case authorizedWhenInUse = 4
    case none = 5
}

public enum RDLocationSource: Int {
    case foregroundLocation
    case backgroundLocation
    case manualLocation
    case geofenceEnter
    case geofenceExit
    case mockLocation
    case unknown
}

extension CLAuthorizationStatus {
    
    var string: String {
        switch self {
            
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown \(self.rawValue)"
        }
    }
    
    var queryStringValue : String {
        switch self {
        case .denied: return RDConstants.locationPermissionNone
        case .authorizedAlways: return RDConstants.locationPermissionAlways
        case .authorizedWhenInUse: return RDConstants.locationPermissionAppOpen
        case .notDetermined, .restricted: return RDConstants.locationPermissionNone
        @unknown default: return RDConstants.locationPermissionNone
        }
    }
    
}
