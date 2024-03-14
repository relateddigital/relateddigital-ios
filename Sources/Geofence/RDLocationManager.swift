//
// RDLocationManager.swift
// RelatedDigitalIOS
//
// Created by Egemen Gülkılık on 29.01.2022.
//

import CoreLocation
import Foundation
import UIKit

let kIdentifierPrefix = "relateddigital_"
let kBubbleGeofenceIdentifierPrefix = "relateddigital_bubble_"
let kSyncGeofenceIdentifierPrefix = "relateddigital_geofence_"

class RDLocationManager: NSObject {
    let options = RDGeofenceOptions()
    var locMan: CLLocationManager
    var lpLocMan: CLLocationManager
    var lastKnownCLAuthorizationStatus: CLAuthorizationStatus?

    var RDProfile: RDProfile?
    var geofenceEnabled = false
    var askLocationPermissionAtStart = false

    private var started = false
    private var startedInterval = 0
    private var sending = false
    private var fetching = false
    private var timer: Timer?

    var lastGeofenceFetchTime = Date(timeIntervalSince1970: 0)
    var geofenceHistory: RDGeofenceHistory

    func getAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locMan.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    override init() {
        locMan = CLLocationManager()
        lpLocMan = CLLocationManager()
        geofenceHistory = RDPersistence.readRDGeofenceHistory()
        super.init()
        locMan.desiredAccuracy = options.desiredCLLocationAccuracy
        locMan.distanceFilter = kCLDistanceFilterNone
        locMan.allowsBackgroundLocationUpdates = options.locationBackgroundMode && getAuthorizationStatus() == .authorizedAlways
        lpLocMan.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        lpLocMan.distanceFilter = 3000
        lpLocMan.allowsBackgroundLocationUpdates = options.locationBackgroundMode
        locMan.delegate = self
        lpLocMan.delegate = self
        RDGeofenceState.setStopped(false)
        updateTracking(location: nil, fromInit: true)
        if let profile = RDPersistence.readRDProfile() {
            RDProfile = profile
            if !RelatedDigital.initializeCalled {
                RelatedDigital.initialize()
            }
            RDHelper.setEndpoints(dataSource: profile.dataSource)
            geofenceEnabled = profile.geofenceEnabled
            askLocationPermissionAtStart = profile.askLocationPermissionAtStart
            if geofenceEnabled {
                startGeofencing(fromInit: true)
            }
        }
    }

    deinit {
        locMan.delegate = nil
        lpLocMan.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    func startGeofencing(fromInit: Bool) {
        if RelatedDigital._shared != nil {
            if askLocationPermissionAtStart {
                requestLocationPermissions()
            }

            let authorizationStatus = RDGeofenceState.locationAuthorizationStatus
            if !(authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) {
                return
            }
            RDGeofenceState.setGeofenceEnabled(true)
            updateTracking(location: nil, fromInit: fromInit)
            if let geoEntities = geofenceHistory.fetchHistory.sorted(by: { $0.key > $1.key }).first?.value {
                replaceSyncedGeofences(geoEntities)
            }
            fetchGeofences()
        }
    }

    func startUpdates(_ interval: Int) {
        if !started || interval != startedInterval {
            RDLogger.info("Starting geofence timer | interval = \(interval)")
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(shutDown), object: nil)
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [self] _ in
                RDLogger.info("Geofence timer fired")
                self.requestLocation()
            }
            lpLocMan.startUpdatingLocation()
            started = true
            startedInterval = interval
        } else {
            // RDLogger.info("Already started geofence timer")
        }
    }

    private func stopUpdates() {
        guard let timer = timer else {
            return
        }
        RDLogger.info("Stopping geofence timer")
        timer.invalidate()
        started = false
        startedInterval = 0
        if !sending {
            let delay: TimeInterval = RDGeofenceState.getGeofenceEnabled() ? 10 : 0
            RDLogger.info("Scheduling geofence shutdown")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.shutDown()
            }
        }
    }

    @objc func shutDown() {
        RDLogger.info("Shutting geofence down")
        lpLocMan.stopUpdatingLocation()
    }

    func requestLocation() {
        RDLogger.info("Requesting location")
        locMan.requestLocation()
    }

    func updateTracking(location: CLLocation?, fromInit: Bool) {
        DispatchQueue.main.async {
            // RDLogger.info("Updating geofence tracking | options = \(self.options); location = \(String(describing: location))")

            if RDGeofenceState.getGeofenceEnabled() {
                self.locMan.allowsBackgroundLocationUpdates = self.options.locationBackgroundMode && self.getAuthorizationStatus() == .authorizedAlways
                if !RDHelper.isiOSAppExtension() {
                    self.locMan.pausesLocationUpdatesAutomatically = false
                }

                self.lpLocMan.allowsBackgroundLocationUpdates = self.options.locationBackgroundMode
                self.lpLocMan.pausesLocationUpdatesAutomatically = false

                self.locMan.desiredAccuracy = self.options.desiredCLLocationAccuracy

                if #available(iOS 11, *) {
                    self.lpLocMan.showsBackgroundLocationIndicator = self.options.showBlueBar
                }

                let startUpdates = self.options.showBlueBar || self.getAuthorizationStatus() == .authorizedAlways
                let stopped = RDGeofenceState.getStopped()
                if stopped {
                    if self.options.desiredStoppedUpdateInterval == 0 {
                        self.stopUpdates()
                    } else if startUpdates {
                        self.startUpdates(self.options.desiredStoppedUpdateInterval)
                    }

                    if self.options.useStoppedGeofence, let location = location {
                        self.replaceBubbleGeofence(location, radius: self.options.stoppedGeofenceRadius)
                    } else {
                        self.removeBubbleGeofence()
                    }

                } else {
                    if self.options.desiredMovingUpdateInterval == 0 {
                        self.stopUpdates()
                    } else if startUpdates {
                        self.startUpdates(self.options.desiredMovingUpdateInterval)
                    }
                    if self.options.useMovingGeofence, let location = location {
                        self.replaceBubbleGeofence(location, radius: self.options.movingGeofenceRadius)
                    } else {
                        self.removeBubbleGeofence()
                    }
                }

                if !self.options.syncGeofences {
                    self.removeSyncedGeofences()
                }
                if self.options.useSignificantLocationChanges {
                    self.locMan.startMonitoringSignificantLocationChanges()
                }

            } else {
                self.stopUpdates()
                self.removeAllRegions()
                if !fromInit {
                    self.locMan.stopMonitoringSignificantLocationChanges()
                }
            }
        }
    }

    func replaceBubbleGeofence(_ location: CLLocation, radius: Int) {
        removeBubbleGeofence()
        if !RDGeofenceState.getGeofenceEnabled() {
            return
        }
        locMan.startMonitoring(for: CLCircularRegion(center: location.coordinate,
                                                     radius: CLLocationDistance(radius),
                                                     identifier: "\(kBubbleGeofenceIdentifierPrefix)\(UUID().uuidString)"))
    }

    func removeBubbleGeofence() {
        for region in locMan.monitoredRegions {
            if region.identifier.hasPrefix(kBubbleGeofenceIdentifierPrefix) {
                locMan.stopMonitoring(for: region)
            }
        }
    }

    func replaceSyncedGeofences(_ geoEntities: [RDGeofenceEntity]) {
        removeSyncedGeofences()
        if !RDGeofenceState.getGeofenceEnabled() || !options.syncGeofences {
            return
        }

        let newGeoEntities = sortAndTakeVisilabsGeofenceEntitiesToMonitor(geoEntities)

        for geoEnt in newGeoEntities {
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: geoEnt.latitude,
                                                                         longitude: geoEnt.longitude),
                                          radius: CLLocationDistance(geoEnt.radius),
                                          identifier: geoEnt.identifier)
            locMan.startMonitoring(for: region)
            RDLogger.info("Synced geofence | lat = \(geoEnt.latitude); lon = \(geoEnt.longitude); rad = \(geoEnt.radius); id \(geoEnt.identifier)")
        }
    }

    func removeSyncedGeofences() {
        for region in locMan.monitoredRegions {
            if region.identifier.hasPrefix(kSyncGeofenceIdentifierPrefix) {
                locMan.stopMonitoring(for: region)
            }
        }
    }

    func removeAllRegions() {
        for region in locMan.monitoredRegions {
            if region.identifier.hasPrefix(kIdentifierPrefix) {
                locMan.stopMonitoring(for: region)
            }
        }
    }
}

extension RDLocationManager {
    func handleLocation(_ location: CLLocation, source: RDLocationSource, region: CLRegion? = nil) {
        if !RDGeofenceState.validLocation(location) {
            RDLogger.info("Invalid location | source = \(source); location = \(String(describing: location))")
            return
        }

        let options = self.options
        let wasStopped = RDGeofenceState.getStopped()
        var stopped = false

        let force = source == .foregroundLocation || source == .manualLocation

        if wasStopped && !force && location.horizontalAccuracy >= 1000 && options.desiredAccuracy != .low {
            RDLogger.info("Skipping location: inaccurate | accuracy = \(location.horizontalAccuracy)")
            updateTracking(location: location, fromInit: false)
            return
        }

        if !force && !RDGeofenceState.getGeofenceEnabled() {
            RDLogger.info("Skipping location: not tracking")
            return
        }

        var distance = CLLocationDistanceMax
        var duration: TimeInterval = 0
        if options.stopDistance > 0, options.stopDuration > 0 {
            var lastMovedLocation: CLLocation?
            var lastMovedAt: Date?

            if RDGeofenceState.getLastMovedLocation() == nil {
                lastMovedLocation = location
                RDGeofenceState.setLastMovedLocation(location)
            }

            if RDGeofenceState.getLastMovedAt() == nil {
                lastMovedAt = location.timestamp
                RDGeofenceState.setLastMovedAt(location.timestamp)
            }

            if !force, let lastMovedAt = lastMovedAt, lastMovedAt.timeIntervalSince(location.timestamp) > 0 {
                RDLogger.info("Skipping location: old | lastMovedAt = \(lastMovedAt); location.timestamp = \(location.timestamp)")
                return
            }

            if let lastMovedLocation = lastMovedLocation, let lastMovedAt = lastMovedAt {
                distance = location.distance(from: lastMovedLocation)
                duration = location.timestamp.timeIntervalSince(lastMovedAt)
                if duration == 0 {
                    duration = -location.timestamp.timeIntervalSinceNow
                }
                stopped = Int(distance) <= options.stopDistance && Int(duration) >= options.stopDuration
                RDLogger.info("Calculating stopped | stopped = \(stopped); distance = \(distance); duration = \(duration); location.timestamp = \(location.timestamp); lastMovedAt = \(lastMovedAt)")

                if Int(distance) > options.stopDistance {
                    RDGeofenceState.setLastMovedLocation(location)
                    if !stopped {
                        RDGeofenceState.setLastMovedAt(location.timestamp)
                    }
                }
            }
        } else {
            stopped = force
        }

        let justStopped = stopped && !wasStopped
        RDGeofenceState.setStopped(stopped)

        if source != .manualLocation {
            updateTracking(location: location, fromInit: false)
        }

        var sendLocation = location

        let lastFailedStoppedLocation = RDGeofenceState.getLastFailedStoppedLocation()
        var replayed = false
        if options.replay == .stops,
           let lastFailedStoppedLocation = lastFailedStoppedLocation,
           !justStopped {
            sendLocation = lastFailedStoppedLocation
            stopped = true
            replayed = true
            RDGeofenceState.setLastFailedStoppedLocation(nil)
            RDLogger.info("Replaying location | location = \(sendLocation); stopped = \(stopped)")
        }
        let lastSentAt = RDGeofenceState.getLastSentAt()
        let ignoreSync = lastSentAt == nil || justStopped || replayed
        let now = Date()
        var lastSyncInterval: TimeInterval?

        if let lastSentAt = lastSentAt {
            lastSyncInterval = now.timeIntervalSince(lastSentAt)
        }

        if !ignoreSync {
            if !force && stopped && wasStopped && Int(distance) <= options.stopDistance && (options.desiredStoppedUpdateInterval == 0 || options.syncLocations != .syncAll) {
                // RDLogger.info("Skipping sync: already stopped | stopped = \(stopped); wasStopped = \(wasStopped)")
                return
            }
            if Int(lastSyncInterval ?? 0) < options.desiredSyncInterval {
                // RDLogger.info("Skipping sync: desired sync interval | desiredSyncInterval = \(options.desiredSyncInterval); lastSyncInterval = \(lastSyncInterval ?? 0)")
            }
            if !force && !justStopped && Int(lastSyncInterval ?? 0) < 1 {
                // RDLogger.info("Skipping sync: rate limit | justStopped = \(justStopped); lastSyncInterval = \(String(describing: lastSyncInterval))")
                return
            }
            if options.syncLocations == .syncNone {
                // RDLogger.info("Skipping sync: sync mode | sync = \(options.syncLocations)")
                return
            }
        }

        RDGeofenceState.setLastSentAt()

        if source == .foregroundLocation {
            return
        }
        self.sendLocation(sendLocation, source: source, region: region)
    }

    func sendLocation(_ location: CLLocation, source: RDLocationSource, region: CLRegion? = nil) {
        sending = true

        if [RDLocationSource.geofenceEnter, RDLocationSource.geofenceExit].contains(source) {
            guard let region = region, region.identifier.hasPrefix(kIdentifierPrefix) else {
                sending = false
                return
            }

            let identifier = region.identifier

            let idArr = identifier.components(separatedBy: "_")
            guard idArr.count >= 4, let actId = Int(idArr[2]), let geoId = Int(idArr[3]) else {
                sending = false
                return
            }
            let targetEvent = idArr[4]

            guard (source == .geofenceEnter && targetEvent == RDConstants.onExit)
                || (source == .geofenceExit && targetEvent == RDConstants.onEnter) else {
                sending = false
                return
            }

            var isDwell = false
            var isEnter = false

            if source == .geofenceEnter, targetEvent == RDConstants.onEnter {
                isDwell = false
                isEnter = true
            } else if source == .geofenceEnter, targetEvent == RDConstants.dwell {
                isDwell = true
                isEnter = true
            } else if source == .geofenceExit, targetEvent == RDConstants.onExit {
                isDwell = false
                isEnter = false
            } else if source == .geofenceExit, targetEvent == RDConstants.dwell {
                isDwell = true
                isEnter = false
            }

            sendPushNotification(actId: actId,
                                 geoId: geoId,
                                 isDwell: isDwell,
                                 isEnter: isEnter) { [weak self] _ in
                self?.sending = false
                self?.updateTracking(location: location, fromInit: false)
            }

        } else {
            sending = false
            fetchGeofences()
        }
    }

    func fetchGeofences() {
        if fetching {
            return
        }
        fetching = true
        let lat = locMan.location?.coordinate.latitude
        let lon = locMan.location?.coordinate.longitude
        getGeofenceList(lastKnownLatitude: lat,
                        lastKnownLongitude: lon) { [weak self] response, fetchedGeofences in
            if response {
                self?.replaceSyncedGeofences(fetchedGeofences)
            }
            self?.fetching = false
            self?.updateTracking(location: self?.locMan.location, fromInit: false)
        }
    }

    func requestLocationPermissions() {
        var status: CLAuthorizationStatus = .notDetermined
        if #available(iOS 14.0, *) {
            status = locMan.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if #available(iOS 13.4, *) {
            if status == .notDetermined {
                locMan.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse {
                locMan.requestAlwaysAuthorization()
            }
        } else {
            locMan.requestAlwaysAuthorization()
        }
    }
}

// MARK: - Permissions

extension RDLocationManager {
    func sendLocationPermission(status: CLAuthorizationStatus? = nil, geofenceEnabled: Bool = true) {
        let authorizationStatus = status ?? RDGeofenceState.locationServiceStateStatus
        if authorizationStatus != lastKnownCLAuthorizationStatus {
            var properties = [String: String]()
            properties[RDConstants.locationPermissionReqKey] = authorizationStatus.queryStringValue
            RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
            lastKnownCLAuthorizationStatus = authorizationStatus
        }
        if !geofenceEnabled {
            self.geofenceEnabled = false
            stopUpdates()
        }
    }
}

// MARK: - Request

extension RDLocationManager {
    func sendPushNotification(actId: Int,
                              geoId: Int,
                              isDwell: Bool,
                              isEnter: Bool,
                              completion: @escaping ((_ response: Bool) -> Void)) {
        guard let profile = RDProfile else {
            return
        }

        let user = RDPersistence.unarchiveUser()
        var props = [String: String]()
        props[RDConstants.organizationIdKey] = profile.organizationId
        props[RDConstants.profileIdKey] = profile.profileId
        props[RDConstants.cookieIdKey] = user.cookieId
        props[RDConstants.exvisitorIdKey] = user.exVisitorId
        props[RDConstants.actKey] = RDConstants.processV2
        props[RDConstants.actidKey] = "\(actId)"
        props[RDConstants.tokenIdKey] = user.tokenId
        props[RDConstants.appidKey] = user.appId
        props[RDConstants.geoIdKey] = "\(geoId)"
        props[RDConstants.utmCampaignKey] = user.utmCampaign
        props[RDConstants.utmContentKey] = user.utmContent
        props[RDConstants.utmMediumKey] = user.utmMedium
        props[RDConstants.utmSourceKey] = user.utmSource
        props[RDConstants.utmTermKey] = user.utmTerm

        props[RDConstants.nrvKey] = String(user.nrv)
        props[RDConstants.pvivKey] = String(user.pviv)
        props[RDConstants.tvcKey] = String(user.tvc)
        props[RDConstants.lvtKey] = user.lvt

        if isDwell {
            props[RDConstants.triggerEventKey] = isEnter ? RDConstants.onEnter : RDConstants.onExit
        }

        for (key, value) in RDPersistence.readTargetParameters() {
            if !key.isEmptyOrWhitespace && !value.isEmptyOrWhitespace && props[key] == nil {
                props[key] = value
            }
        }
        RDLogger.info("Geofence Triggerred: actionId: \(actId) geofenceid: \(geoId)")
        RDRequest.sendGeofenceRequest(properties: props,
                                      headers: [String: String]()) { _, error in
            if let error = error {
                RDLogger.error("Geofence Push Send Error: \(error)")
            }
            completion(true)
        }
    }

    func getGeofenceList(lastKnownLatitude: Double?,
                         lastKnownLongitude: Double?,
                         completion: @escaping ((_ response: Bool, _ fetchedGeofences: [RDGeofenceEntity]) -> Void)) {
        DispatchQueue.global().async { [self] in

            guard let profile = RDProfile else {
                completion(false, [RDGeofenceEntity]())
                return
            }

            if profile.geofenceEnabled, RDGeofenceState.locationServicesEnabledForDevice, RDGeofenceState.locationServiceEnabledForApplication {
                let now = Date()
                let timeInterval = now.timeIntervalSince1970 - self.lastGeofenceFetchTime.timeIntervalSince1970
                if timeInterval < RDConstants.geofenceFetchTimeInterval {
                    completion(false, [RDGeofenceEntity]())
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
                props[RDConstants.utmCampaignKey] = user.utmCampaign
                props[RDConstants.utmContentKey] = user.utmContent
                props[RDConstants.utmMediumKey] = user.utmMedium
                props[RDConstants.utmSourceKey] = user.utmSource
                props[RDConstants.utmTermKey] = user.utmTerm
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

                RDRequest.sendGeofenceRequest(properties: props, headers: [String: String]()) {
                    [lastKnownLatitude, lastKnownLongitude, geofenceHistory, now] result, error in

                    if error != nil {
                        self.geofenceHistory.lastKnownLatitude = lastKnownLatitude ?? geofenceHistory.lastKnownLatitude
                        self.geofenceHistory.lastKnownLongitude = lastKnownLongitude ?? geofenceHistory.lastKnownLongitude
                        if self.geofenceHistory.errorHistory.count > RDConstants.geofenceHistoryErrorMaxCount {
                            let ascendingKeys = Array(self.geofenceHistory.errorHistory.keys).sorted(by: { $0 < $1 })
                            let keysToBeDeleted = ascendingKeys[0 ..< (ascendingKeys.count
                                    - RDConstants.geofenceHistoryErrorMaxCount)]
                            for key in keysToBeDeleted {
                                self.geofenceHistory.errorHistory[key] = nil
                            }
                        }
                        RDPersistence.saveRDGeofenceHistory(self.geofenceHistory)
                        completion(false, [RDGeofenceEntity]())
                        return
                    }
                    self.geofenceHistory.lastFetchTime = now
                    var fetchedGeofences = [RDGeofenceEntity]()
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
                                        fetchedGeofences.append(RDGeofenceEntity(actId: actionId,
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
                        let keysToBeDeleted = ascendingKeys[0 ..< (ascendingKeys.count
                                - RDConstants.geofenceHistoryMaxCount)]
                        for key in keysToBeDeleted {
                            self.geofenceHistory.fetchHistory[key] = nil
                        }
                    }
                    RDPersistence.saveRDGeofenceHistory(self.geofenceHistory)
                    completion(true, fetchedGeofences)
                }
            }
        }
    }

    private func sortAndTakeVisilabsGeofenceEntitiesToMonitor(_ geofences: [RDGeofenceEntity])
        -> [RDGeofenceEntity] {
        let geofencesSortedAscending = geofences.sorted { first, second -> Bool in
            let firstDistance = first.distanceFromCurrentLastKnownLocation ?? Double.greatestFiniteMagnitude
            let secondDistance = second.distanceFromCurrentLastKnownLocation ?? Double.greatestFiniteMagnitude
            return firstDistance < secondDistance
        }
        var geofencesToMonitor = [RDGeofenceEntity]()
        for geofence in geofencesSortedAscending {
            if geofencesToMonitor.count == RDProfile?.maxGeofenceCount {
                break
            }
            geofencesToMonitor.append(geofence)
        }
        return [RDGeofenceEntity](geofencesToMonitor)
    }
}

// MARK: - CLLocationManagerDelegate

extension RDLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            handleLocation(location, source: .backgroundLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let location = manager.location, region.identifier.hasPrefix(kIdentifierPrefix) else {
            return
        }
        handleLocation(location, source: .geofenceEnter, region: region)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let location = manager.location, region.identifier.hasPrefix(kIdentifierPrefix) else {
            return
        }
        handleLocation(location, source: .geofenceExit, region: region)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        RDLogger.info("CLLocationManager didChangeAuthorization: status: \(status.string)")
        sendLocationPermission(status: status)
        startGeofencing(fromInit: true)
    }

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        RDLogger.info("CLLocationManager didChangeAuthorization: status: \(manager.authorizationStatus.string)")
        sendLocationPermission(status: manager.authorizationStatus)
        startGeofencing(fromInit: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        RDLogger.error("CLLocationManager didFailWithError : \(error.localizedDescription)")
    }
}
