//
//  RDGeofenceOptions.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 5.07.2022.
//


import Foundation
import CoreLocation

class RDGeofenceOptions {
    var desiredStoppedUpdateInterval = 0
    var desiredMovingUpdateInterval = 150
    var desiredSyncInterval = 20
    var desiredAccuracy = LocationDesiredAccuracy.medium
    var stopDuration = 140
    var stopDistance = 70
    var replay = LocationReplay.none
    var syncLocations = SyncLocations.syncAll
    var showBlueBar = false
    var useStoppedGeofence = true
    var stoppedGeofenceRadius = 100
    var useMovingGeofence = false
    var movingGeofenceRadius = 0
    var syncGeofences = true
    var useSignificantLocationChanges = true
    
    var desiredCLLocationAccuracy: CLLocationAccuracy {
        if desiredAccuracy == .medium {
            return kCLLocationAccuracyHundredMeters
        } else if desiredAccuracy == .high {
            return kCLLocationAccuracyBest
        } else {
            return kCLLocationAccuracyKilometer
        }
    }
    
    var locationBackgroundMode: Bool {
        let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String]
        return backgroundModes != nil && backgroundModes?.contains("location") ?? false
    }
    
}

enum LocationDesiredAccuracy: Int {
    case high
    case medium
    case low
}

enum LocationReplay: Int {
    case stops
    case none
}

enum SyncLocations: Int {
    case syncAll
    case syncStopsAndExits
    case syncNone
}
