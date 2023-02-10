//
// RDGeofenceEntity.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

public class RDGeofenceEntity: Codable {
    internal init(actId: Int,
                  geofenceId: Int,
                  latitude: Double,
                  longitude: Double,
                  radius: Double,
                  durationInSeconds: Int,
                  targetEvent: String,
                  distanceFromCurrentLastKnownLocation: Double?) {
        self.actId = actId
        self.geofenceId = geofenceId
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.durationInSeconds = durationInSeconds
        self.targetEvent = targetEvent
        self.distanceFromCurrentLastKnownLocation = distanceFromCurrentLastKnownLocation
        self.identifier = "relateddigital_geofence_\(self.actId)_\(self.geofenceId)_\(self.targetEvent)"
    }
    public var actId: Int
    public var geofenceId: Int
    public var latitude: Double
    public var longitude: Double
    public var radius: Double
    public var durationInSeconds: Int
    public var targetEvent: String
    public var distanceFromCurrentLastKnownLocation: Double?
    public var identifier: String
}
