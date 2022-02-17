//
// RDCLAuthorizationStatus.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

import Foundation

public enum RDCLAuthorizationStatus: Int32 {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorizedAlways = 3
    case authorizedWhenInUse = 4
    case none = 5
}
