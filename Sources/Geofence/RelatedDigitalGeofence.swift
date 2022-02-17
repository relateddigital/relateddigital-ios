//
//  VisilabsGeofence.swift
//  VisilabsIOS
//
//  Created by Egemen on 10.06.2020.
//

import Foundation
import CoreLocation

class RelatedDigitalGeofence {

    static let sharedManager = RelatedDigitalGeofence()

    var activeGeofenceList: [RelatedDigitalGeofenceEntity]
    let profile: RDProfile
    var geofenceHistory: RelatedDigitalGeofenceHistory
    private var lastGeofenceFetchTime: Date
    private var lastSuccessfulGeofenceFetchTime: Date

    init?() {
        if let profile = RDPersistence.readRDProfile() {
            self.profile = profile
            RDHelper.setEndpoints(dataSource: self.profile.dataSource)// TO_DO: bunu if içine almaya gerek var mı?
            self.activeGeofenceList = [RelatedDigitalGeofenceEntity]()
            self.geofenceHistory = RDPersistence.readRDGeofenceHistory()
            self.lastGeofenceFetchTime = Date(timeIntervalSince1970: 0)
            self.lastSuccessfulGeofenceFetchTime = Date(timeIntervalSince1970: 0)
        } else {
            return nil
        }
    }

    var locationServicesEnabledForDevice: Bool {
        return RelatedDigitalLocationManager.locationServicesEnabledForDevice
    }

    // notDetermined, restricted, denied, authorizedAlways, authorizedWhenInUse
    var locationServiceStateStatusForApplication: RelatedDigitalCLAuthorizationStatus {
        return RelatedDigitalCLAuthorizationStatus(rawValue:
                            RelatedDigitalLocationManager.locationServiceStateStatus.rawValue) ?? .none
    }

    private var locationServiceEnabledForApplication: Bool {
        return self.locationServiceStateStatusForApplication == .authorizedAlways
            || self.locationServiceStateStatusForApplication == .authorizedWhenInUse
    }

    func startGeofencing() {
        RelatedDigitalLocationManager.sharedManager.startGeofencing()
    }

    private func startMonitorGeofences(geofences: [RelatedDigitalGeofenceEntity]) {
        RelatedDigitalLocationManager.sharedManager.stopMonitorRegions()
        self.activeGeofenceList = sortAndTakeRelatedDigitalGeofenceEntitiesToMonitor(geofences)
        if self.profile.geofenceEnabled
            && self.locationServicesEnabledForDevice
            && self.locationServiceEnabledForApplication {
            for geofence in self.activeGeofenceList {
                let geoRegion = CLCircularRegion(center:
                    CLLocationCoordinate2DMake(geofence.latitude, geofence.longitude),
                    radius: geofence.radius,
                    identifier: geofence.identifier)
                RelatedDigitalLocationManager.sharedManager.startMonitorRegion(region: geoRegion)
            }
        }
    }

    private func sortAndTakeRelatedDigitalGeofenceEntitiesToMonitor(_ geofences: [RelatedDigitalGeofenceEntity])
                                                                    -> [RelatedDigitalGeofenceEntity] {
        let geofencesSortedAscending = geofences.sorted { (first, second) -> Bool in
            let firstDistance = first.distanceFromCurrentLastKnownLocation ?? Double.greatestFiniteMagnitude
            let secondDistance = second.distanceFromCurrentLastKnownLocation ?? Double.greatestFiniteMagnitude
            return firstDistance < secondDistance
        }
        var geofencesToMonitor = [RelatedDigitalGeofenceEntity]()
        for geofence in geofencesSortedAscending {
            if geofencesToMonitor.count == self.profile.maxGeofenceCount {
                break
            }
            geofencesToMonitor.append(geofence)
        }
        return [RelatedDigitalGeofenceEntity](geofencesToMonitor)
    }
    // swiftlint:disable function_body_length cyclomatic_complexity
    func getGeofenceList(lastKnownLatitude: Double?, lastKnownLongitude: Double?) {
        if profile.geofenceEnabled, locationServicesEnabledForDevice, locationServiceEnabledForApplication {
            let now = Date()
            let timeInterval = now.timeIntervalSince1970 - self.lastGeofenceFetchTime.timeIntervalSince1970
            if timeInterval < RDConstants.geofenceFetchTimeInterval {
                return
            }

            self.lastGeofenceFetchTime = now
            let user = RDPersistence.unarchiveUser()
            let geofenceHistory = RDPersistence.readRDGeofenceHistory()
            var props = [String: String]()
            props[RDConstants.organizationIdKey] = profile.organizationId
            props[RDConstants.profileIdKey] = profile.profileId
            props[RDConstants.cookieIdKey] = user.cookieId
            props[RDConstants.exvisitorIdKey] = user.exVisitorId
            props[RDConstants.actKey] = RDConstants.getList
            props[RDConstants.tokenIdKey] = user.tokenId
            props[RDConstants.appidKey] = user.appId
            props[RDConstants.channelKey] = profile.channel
            if let lat = lastKnownLatitude, let lon = lastKnownLongitude {
                props[RDConstants.latitudeKey] = String(format: "%.013f", lat)
                props[RDConstants.longitudeKey] = String(format: "%.013f", lon)
            } else if let lat = geofenceHistory.lastKnownLatitude, let lon = geofenceHistory.lastKnownLongitude {
                props[RDConstants.latitudeKey] = String(format: "%.013f", lat)
                props[RDConstants.longitudeKey] = String(format: "%.013f", lon)
            }
            
            props[RDConstants.nrvKey] = String(user.nrv)
            props[RDConstants.pvivKey] = String(user.pviv)
            props[RDConstants.tvcKey] = String(user.tvc)
            props[RDConstants.lvtKey] = user.lvt

            for (key, value) in RDPersistence.readTargetParameters() {
               if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                   props[key] = value
               }
            }
            // swiftlint:disable closure_parameter_position
            RDRequest.sendGeofenceRequest(properties: props, headers: [String: String]()) {
                [lastKnownLatitude, lastKnownLongitude, geofenceHistory, now] (result, error) in

                if error != nil {
                    self.geofenceHistory.lastKnownLatitude = lastKnownLatitude ?? geofenceHistory.lastKnownLatitude
                    self.geofenceHistory.lastKnownLongitude = lastKnownLongitude ?? geofenceHistory.lastKnownLongitude
                    if self.geofenceHistory.errorHistory.count > RDConstants.geofenceHistoryErrorMaxCount {
                        let ascendingKeys = Array(self.geofenceHistory.errorHistory.keys).sorted(by: { $0 < $1 })
                        let keysToBeDeleted = ascendingKeys[0..<(ascendingKeys.count
                                            - RDConstants.geofenceHistoryErrorMaxCount)]
                        for key in keysToBeDeleted {
                            self.geofenceHistory.errorHistory[key] = nil
                        }
                    }
                    RDPersistence.saveRDGeofenceHistory(self.geofenceHistory)
                    return
                }
                (self.lastSuccessfulGeofenceFetchTime, self.geofenceHistory.lastFetchTime) = (now, now)
                var fetchedGeofences = [RelatedDigitalGeofenceEntity]()
                if let res = result {
                    for targetingAction in res {
                        if let actionId = targetingAction["actid"] as? Int,
                           let targetEvent = targetingAction["trgevt"] as? String,
                           let durationInSeconds = targetingAction["dis"] as? Int,
                           let geofences = targetingAction["geo"] as? [[String: Any]] {

                            for geofence in geofences {
                                if let geofenceId = geofence["id"] as? Int,
                                   let latitude = geofence["lat"] as? Double,
                                   let longitude = geofence["long"] as? Double,
                                   let radius = geofence["rds"] as? Double {
                                    var distanceFromCurrentLastKnownLocation: Double?
                                    if let lastLat = lastKnownLatitude, let lastLong = lastKnownLongitude {
                            distanceFromCurrentLastKnownLocation = RDHelper.distanceSquared(lat1: lastLat,
                                                                            lng1: lastLong,
                                                                            lat2: latitude,
                                                                            lng2: longitude)
                                    }
                                    fetchedGeofences.append(RelatedDigitalGeofenceEntity(actId: actionId,
                                                                                   geofenceId: geofenceId,
                                                                                   latitude: latitude,
                                                                                   longitude: longitude,
                                                                                   radius: radius,
                                                                                   durationInSeconds: durationInSeconds,
                                                                                   targetEvent: targetEvent,
                                        distanceFromCurrentLastKnownLocation: distanceFromCurrentLastKnownLocation))
                                }
                            }
                        }
                    }
                }
                self.geofenceHistory.lastFetchTime = now
                self.geofenceHistory.lastKnownLatitude = lastKnownLatitude
                self.geofenceHistory.lastKnownLongitude = lastKnownLongitude
                self.geofenceHistory.fetchHistory[now] = fetchedGeofences
                if self.geofenceHistory.fetchHistory.count > RDConstants.geofenceHistoryMaxCount {
                    let ascendingKeys = Array(self.geofenceHistory.fetchHistory.keys).sorted(by: { $0 < $1 })
                    let keysToBeDeleted = ascendingKeys[0..<(ascendingKeys.count
                                                            - RDConstants.geofenceHistoryMaxCount)]
                    for key in keysToBeDeleted {
                        self.geofenceHistory.fetchHistory[key] = nil
                    }
                }
                // self.geofenceHistory = geofenceHistory
                RDPersistence.saveRDGeofenceHistory(self.geofenceHistory)
                self.startMonitorGeofences(geofences: fetchedGeofences)
            }
        }
    }

    func sendPushNotification(actionId: String, geofenceId: String, isDwell: Bool, isEnter: Bool) {
        let user = RDPersistence.unarchiveUser()
        var props = [String: String]()
        props[RDConstants.organizationIdKey] = profile.organizationId
        props[RDConstants.profileIdKey] = profile.profileId
        props[RDConstants.cookieIdKey] = user.cookieId
        props[RDConstants.exvisitorIdKey] = user.exVisitorId
        props[RDConstants.actKey] = RDConstants.processV2
        props[RDConstants.actidKey] = actionId
        props[RDConstants.tokenIdKey] = user.tokenId
        props[RDConstants.appidKey] = user.appId
        props[RDConstants.geoIdKey] = geofenceId
        
        props[RDConstants.nrvKey] = String(user.nrv)
        props[RDConstants.pvivKey] = String(user.pviv)
        props[RDConstants.tvcKey] = String(user.tvc)
        props[RDConstants.lvtKey] = user.lvt

        if isDwell {
            if isEnter {
                props[RDConstants.triggerEventKey] = RDConstants.onEnter
            } else {
                props[RDConstants.triggerEventKey] = RDConstants.onExit
            }
        }

        for (key, value) in RDPersistence.readTargetParameters() {
           if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
               props[key] = value
           }
        }
        RDLogger.info("Geofence Triggerred: actionId: \(actionId) geofenceid: \(geofenceId)")
        RDRequest.sendGeofenceRequest(properties: props) { (_, error) in
            if let error = error {
                RDLogger.error("Geofence Push Send Error: \(error)")
            }
        }
    }

}
