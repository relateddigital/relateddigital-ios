//
//  VisilabsGeofenceHistory.swift
//  VisilabsIOS
//
//  Created by Egemen on 1.09.2020.
//

import Foundation

public class RelatedDigitalGeofenceHistory: Codable {
    internal init(lastKnownLatitude: Double? = nil,
                  lastKnownLongitude: Double? = nil,
                  lastFetchTime: Date? = nil,
                  fetchHistory: [Date: [RelatedDigitalGeofenceEntity]]? = nil,
                  errorHistory: [Date: RDError]? = nil) {
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.lastFetchTime = lastFetchTime
        self.fetchHistory = fetchHistory ?? [Date: [RelatedDigitalGeofenceEntity]]()
        self.errorHistory = errorHistory ??  [Date: RDError]()
    }

    internal init() {
        self.fetchHistory = [Date: [RelatedDigitalGeofenceEntity]]()
        self.errorHistory = [Date: RDError]()
    }
    public var lastKnownLatitude: Double?
    public var lastKnownLongitude: Double?
    public var lastFetchTime: Date?
    public var fetchHistory: [Date: [RelatedDigitalGeofenceEntity]]
    public var errorHistory: [Date: RDError]
}
