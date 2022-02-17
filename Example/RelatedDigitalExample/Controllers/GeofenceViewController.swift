//
//  GeofenceViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 13.07.2021.
//

import UIKit
import RelatedDigitalIOS
import CleanyModal

class GeofenceViewController: FormViewController {
    
    let locationEnabledDevice = "Location Enabled(Device)"
    let locationStatusApp = "Location Status(App)"
    let lastFetchTime = "Last Fetch Time"
    let lastKnownLatitude = "Last Known Latitude"
    let lastKnownLongitude = "Last Known Longitude"

    let dateFormatter = DateFormatter()
    var relatedDigitalGeofenceHistory: RelatedDigitalGeofenceHistory!
    var historySection = Section("Geofence Server Checks".uppercased(with: Locale(identifier: "en_US")))
    var errorSection = Section("Geofence Server Checks With Error".uppercased(with: Locale(identifier: "en_US")))
    var refreshSection = Section()
    var locationServicesEnabledForDeviceRow: TextRow!
    var locationServiceStatusForAppRow: TextRow!
    var lastFetchTimeRow: TextRow!
    var lastKnownLatitudeRow: TextRow!
    var lastKnownLongitudeRow: TextRow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        initializeForm()
    }
    
    private func initializeForm() {
        refreshSection.append(ButtonRow {
            $0.title = "Clear History"
        }
        .onCellSelection { _, _ in
            self.clearHistory()
        })
        refreshSection.append(ButtonRow {
            $0.title = "Refresh"
        }
        .onCellSelection { _, _ in
            self.refreshData(firstTime: false)
        })
        locationServicesEnabledForDeviceRow = TextRow(locationEnabledDevice) {
            $0.title = locationEnabledDevice
            $0.disabled = true
        }
        locationServiceStatusForAppRow = TextRow(locationStatusApp) {
            $0.title = locationStatusApp
            $0.disabled = true
        }
        lastFetchTimeRow = TextRow(lastFetchTime) {
            $0.title = lastFetchTime
            $0.disabled = true
        }
        lastKnownLatitudeRow = TextRow(lastKnownLatitude) {
            $0.title = lastKnownLatitude
            $0.disabled = true
        }
        lastKnownLongitudeRow = TextRow(lastKnownLongitude) {
            $0.title = lastKnownLongitude
            $0.disabled = true
        }
        refreshSection.append(locationServicesEnabledForDeviceRow)
        refreshSection.append(locationServiceStatusForAppRow)
        refreshSection.append(lastFetchTimeRow)
        refreshSection.append(lastKnownLatitudeRow)
        refreshSection.append(lastKnownLongitudeRow)

        form.append(refreshSection)
        form.append(historySection)
        form.append(errorSection)
        self.refreshData(firstTime: true)
    }
    
    var currentHistoryRowTags = [String: Bool]()
    var currentErrorRowTags = [String: Bool]()

    private func getHistoryRow(tag: String, date: Date)-> ButtonRowOf<Date> {
        return ButtonRowOf<Date>(tag) {
            $0.title = dateFormatter.string(from: date)
            $0.value = date
        }
        .onCellSelection { _, row in
            let entities = self.relatedDigitalGeofenceHistory.fetchHistory[row.value!]
            let alert = GeofenceAlertViewController(date: row.value!, relatedDigitalGeofenceEntities: entities)
            alert.addAction(title: "Dismiss", style: .default)
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func getErrorRow(tag: String, date: Date) -> ButtonRowOf<Date> {
        return ButtonRowOf<Date>(tag) {
            $0.title = dateFormatter.string(from: date)
            $0.value = date
        }
        .onCellSelection { _, row in
            let errorHistory = self.relatedDigitalGeofenceHistory.errorHistory[row.value!]
            let alert = GeofenceAlertViewController(date: row.value!,
                                                    relatedDigitalError: errorHistory)
            alert.addAction(title: "Dismiss", style: .default)
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func refreshData(firstTime: Bool = false) {
        relatedDigitalGeofenceHistory = RDPersistence.readRDGeofenceHistory()
        locationServicesEnabledForDeviceRow.value = RelatedDigital.locationServicesEnabledForDevice ? "YES" : "NO"
        let state = RelatedDigital.locationServiceStateStatusForApplication
        locationServiceStatusForAppRow.value = String(describing: state)
        let time = relatedDigitalGeofenceHistory.lastFetchTime
        lastFetchTimeRow.value = dateFormatter.string(from: time ?? Date(timeIntervalSince1970: 0))
        lastKnownLatitudeRow.value = String(format: "%.013f", relatedDigitalGeofenceHistory.lastKnownLatitude ?? 0.0)
        lastKnownLongitudeRow.value = String(format: "%.013f", relatedDigitalGeofenceHistory.lastKnownLongitude ?? 0.0)
        refreshSection.reload()
        for date in relatedDigitalGeofenceHistory.fetchHistory.keys.sorted(by: >) {
            let tag = String(Int64((date.timeIntervalSince1970 * 1000.0).rounded()))
            if currentHistoryRowTags[tag] != nil {
                return
            }
            if firstTime {
                historySection.append(getHistoryRow(tag: tag, date: date))
            } else {
                historySection.insert(getHistoryRow(tag: tag, date: date), at: 0)
            }
            currentHistoryRowTags[tag] = true
        }
        for date in relatedDigitalGeofenceHistory.errorHistory.keys.sorted(by: >) {
            let tag = String(Int64((date.timeIntervalSince1970 * 1000.0).rounded()))
            if currentErrorRowTags[tag] != nil {
                return
            }
            if firstTime {
                errorSection.append(getErrorRow(tag: tag, date: date))
            } else {
                errorSection.insert(getErrorRow(tag: tag, date: date), at: 0)
            }
            currentHistoryRowTags[tag] = true
        }
        historySection.reload()
        errorSection.reload()
    }

    private func clearHistory() {
        RDPersistence.clearRDGeofenceHistory()
        historySection.removeAll()
        historySection.reload()
        errorSection.removeAll()
        errorSection.reload()
    }
    
}

class GeofenceAlertViewController: CleanyAlertViewController {
    let dateFormatter = DateFormatter()

    init(date: Date, relatedDigitalError: RDError?) {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let styleSettings = CleanyAlertConfig.getDefaultStyleSettings()
        styleSettings[.cornerRadius] = 18
        super.init(title: dateFormatter.string(from: date),
                   message: relatedDigitalError.debugDescription,
                   preferredStyle: .alert,
                   styleSettings: styleSettings)
    }

    init(date: Date, relatedDigitalGeofenceEntities: [RelatedDigitalGeofenceEntity]?) {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let styleSettings = CleanyAlertConfig.getDefaultStyleSettings()
        styleSettings[.cornerRadius] = 18
        var message = "There is no data"
        if let geofences = relatedDigitalGeofenceEntities, geofences.count > 0 {
            message = GeofenceAlertViewController.getMessageFromGeofenceEntities(geofences)
        }

        super.init(title: dateFormatter.string(from: date),
                   message: message,
                   preferredStyle: .alert,
                   styleSettings: styleSettings)
    }

    private static func getMessageFromGeofenceEntities(_ geofences: [RelatedDigitalGeofenceEntity]) -> String {
        var message = ""
        for geofence in geofences {
            message += "actid:\(geofence.actId) geoid\(geofence.geofenceId)" +  "\n"
        }
        return message
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
