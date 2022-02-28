//
// RDGeofenceHistory.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

import Foundation

public class RDGeofenceHistory: Codable {
    internal init(lastKnownLatitude: Double? = nil,
                  lastKnownLongitude: Double? = nil,
                  lastFetchTime: Date? = nil,
                  fetchHistory: [Date: [RDGeofenceEntity]]? = nil,
                  errorHistory: [Date: RDError]? = nil) {
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.lastFetchTime = lastFetchTime
        self.fetchHistory = fetchHistory ?? [Date: [RDGeofenceEntity]]()
        self.errorHistory = errorHistory ??  [Date: RDError]()
    }

    internal init() {
        self.fetchHistory = [Date: [RDGeofenceEntity]]()
        self.errorHistory = [Date: RDError]()
    }
    public var lastKnownLatitude: Double?
    public var lastKnownLongitude: Double?
    public var lastFetchTime: Date?
    public var fetchHistory: [Date: [RDGeofenceEntity]]
    public var errorHistory: [Date: RDError]
}
