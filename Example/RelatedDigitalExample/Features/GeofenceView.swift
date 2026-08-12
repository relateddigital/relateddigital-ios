//
//  GeofenceView.swift
//  RelatedDigitalExample
//
//  Location state plus the geofence fetch history the SDK persists locally.
//

import RelatedDigitalIOS
import SwiftUI

struct GeofenceView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var toast: ToastCenter

    @State private var history: GeofenceSnapshot = .empty

    var body: some View {
        Screen(title: "Geofence",
               subtitle: "Server checks are performed every 15 minutes while location access is granted.") {

            if !config.geofenceEnabled {
                Banner(title: "Geofence module is off",
                       message: "No server checks will run. Enable it from Overview → Modules and relaunch for a clean start.",
                       systemImage: "exclamationmark.triangle.fill",
                       tint: Theme.warning)
            }

            Card(title: "Location state", systemImage: "location.fill") {
                InfoRow(label: "Device services", value: history.deviceServicesEnabled, isMonospaced: false)
                RowDivider()
                InfoRow(label: "App authorization", value: history.appAuthorization, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Last fetch", value: history.lastFetchTime, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Latitude", value: history.latitude)
                RowDivider()
                InfoRow(label: "Longitude", value: history.longitude)
                RowDivider()
                ActionRow(title: "Refresh", subtitle: "RDPersistence.readRDGeofenceHistory()",
                          systemImage: "arrow.clockwise") {
                    reload()
                    toast.show("Geofence history reloaded")
                }
            }

            Card(title: "Server checks", systemImage: "checkmark.seal.fill",
                 footnote: history.fetches.isEmpty ? nil : "\(history.fetches.count) recorded check(s), newest first.") {
                if history.fetches.isEmpty {
                    EmptyState(systemImage: "mappin.slash",
                               title: "No checks recorded",
                               message: "Move the simulated location or wait for the next fetch window.")
                } else {
                    ForEach(Array(history.fetches.enumerated()), id: \.element.id) { index, fetch in
                        if index > 0 { RowDivider() }
                        NavigationLink { GeofenceFetchDetailView(fetch: fetch) } label: {
                            fetchRow(fetch)
                        }
                    }
                }
            }

            Card(title: "Errors", systemImage: "exclamationmark.triangle.fill") {
                if history.errors.isEmpty {
                    EmptyState(systemImage: "checkmark.circle",
                               title: "No errors",
                               message: "Failed geofence requests would be listed here.")
                } else {
                    ForEach(Array(history.errors.enumerated()), id: \.element.id) { index, error in
                        if index > 0 { RowDivider() }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(error.timestamp)
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                            Text(error.message)
                                .font(.caption)
                                .foregroundStyle(Theme.danger)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, Theme.Spacing.m)
                    }
                }
            }

            Card(title: "Maintenance", systemImage: "trash.fill") {
                ActionRow(title: "Clear history",
                          subtitle: "RDPersistence.clearRDGeofenceHistory()",
                          systemImage: "trash.fill",
                          tint: Theme.danger) {
                    RDLog.call("clearRDGeofenceHistory()", channel: .geofence)
                    RDPersistence.clearRDGeofenceHistory()
                    reload()
                    toast.show("Geofence history cleared", icon: "trash.fill", tint: Theme.danger)
                }
            }
        }
        .onAppear(perform: reload)
    }

    private func fetchRow(_ fetch: GeofenceSnapshot.Fetch) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fetch.timestamp)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(fetch.entities.count) geofence(s)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: Theme.Spacing.s)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
    }

    private func reload() {
        history = GeofenceSnapshot.current()
    }
}

// MARK: - Detail

struct GeofenceFetchDetailView: View {

    let fetch: GeofenceSnapshot.Fetch

    var body: some View {
        Screen(title: "Server check", subtitle: fetch.timestamp) {
            if fetch.entities.isEmpty {
                Card { EmptyState(systemImage: "mappin.slash",
                                  title: "Empty response",
                                  message: "The check completed but returned no geofences.") }
            } else {
                ForEach(fetch.entities) { entity in
                    Card(title: "Action \(entity.actId) · Geofence \(entity.geofenceId)",
                         systemImage: "mappin.circle.fill") {
                        InfoRow(label: "Target event", value: entity.targetEvent, isMonospaced: false)
                        RowDivider()
                        InfoRow(label: "Latitude", value: entity.latitude)
                        RowDivider()
                        InfoRow(label: "Longitude", value: entity.longitude)
                        RowDivider()
                        InfoRow(label: "Radius", value: entity.radius, isMonospaced: false)
                        RowDivider()
                        InfoRow(label: "Distance", value: entity.distance, isMonospaced: false)
                        RowDivider()
                        InfoRow(label: "Identifier", value: entity.identifier)
                    }
                }
            }
        }
    }
}

// MARK: - Snapshot

/// Value copy of the SDK's geofence history so SwiftUI has stable identities.
struct GeofenceSnapshot {

    struct Entity: Identifiable {
        let id = UUID()
        let actId: Int
        let geofenceId: Int
        let targetEvent: String
        let latitude: String
        let longitude: String
        let radius: String
        let distance: String
        let identifier: String
    }

    struct Fetch: Identifiable {
        let id = UUID()
        let timestamp: String
        let entities: [Entity]
    }

    struct Failure: Identifiable {
        let id = UUID()
        let timestamp: String
        let message: String
    }

    var deviceServicesEnabled = "—"
    var appAuthorization = "—"
    var lastFetchTime = "—"
    var latitude = ""
    var longitude = ""
    var fetches: [Fetch] = []
    var errors: [Failure] = []

    static let empty = GeofenceSnapshot()

    static func current() -> GeofenceSnapshot {
        let history = RDPersistence.readRDGeofenceHistory()
        var snapshot = GeofenceSnapshot()

        snapshot.deviceServicesEnabled = RelatedDigital.locationServicesEnabledForDevice ? "Enabled" : "Disabled"
        snapshot.appAuthorization = String(describing: RelatedDigital.locationServiceStateStatusForApplication)
        snapshot.lastFetchTime = history.lastFetchTime.map(formatter.string(from:)) ?? "Never"
        snapshot.latitude = history.lastKnownLatitude.map { String(format: "%.7f", $0) } ?? ""
        snapshot.longitude = history.lastKnownLongitude.map { String(format: "%.7f", $0) } ?? ""

        snapshot.fetches = history.fetchHistory.keys.sorted(by: >).map { date in
            Fetch(timestamp: formatter.string(from: date),
                  entities: (history.fetchHistory[date] ?? []).map(Entity.init))
        }

        snapshot.errors = history.errorHistory.keys.sorted(by: >).map { date in
            Failure(timestamp: formatter.string(from: date),
                    message: String(describing: history.errorHistory[date]))
        }

        return snapshot
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}

private extension GeofenceSnapshot.Entity {
    init(_ entity: RDGeofenceEntity) {
        self.init(actId: entity.actId,
                  geofenceId: entity.geofenceId,
                  targetEvent: entity.targetEvent,
                  latitude: String(format: "%.7f", entity.latitude),
                  longitude: String(format: "%.7f", entity.longitude),
                  radius: "\(Int(entity.radius)) m",
                  distance: entity.distanceFromCurrentLastKnownLocation
                      .map { "\(Int($0)) m" } ?? "—",
                  identifier: entity.identifier)
    }
}
