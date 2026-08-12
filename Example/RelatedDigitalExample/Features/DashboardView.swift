//
//  DashboardView.swift
//  RelatedDigitalExample
//
//  Landing screen: what the SDK booted with, who the current visitor is, and
//  entry points to the less frequently used modules.
//

import RelatedDigitalIOS
import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var push: PushCenter
    @EnvironmentObject private var toast: ToastCenter

    @State private var user = RDUserSnapshot()

    /// Environment the SDK booted with — pending edits do not move this.
    private var activeEnvironment: SDKEnvironment {
        config.activeSnapshot.useTestEnvironment ? .test : .production
    }

    var body: some View {
        Screen(title: "Related Digital",
               subtitle: "SDK \(user.sdkVersion) · sample application") {

            statusCard
            identityCard
            sessionCard
            modulesCard
            toolsCard
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .onAppear(perform: refresh)
    }

    // MARK: - Cards

    private var statusCard: some View {
        Card(title: "Status", systemImage: "bolt.horizontal.fill") {
            HStack(spacing: Theme.Spacing.s) {
                Pill(text: config.isSDKReady ? "SDK ready" : "Not initialized",
                     tint: config.isSDKReady ? Theme.success : Theme.danger,
                     systemImage: config.isSDKReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                // Reflects what the SDK actually booted with, not pending edits.
                Pill(text: activeEnvironment.displayName,
                     tint: activeEnvironment == .test ? Theme.warning : Theme.info,
                     systemImage: "network")
                Pill(text: "Push · \(push.statusText)", tint: push.statusTint, systemImage: "bell.fill")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.m)

            if config.needsRelaunch {
                RowDivider()
                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.warning)
                    Text("Configuration changed. `initialize` runs once per process — relaunch the app for the new organization, profile, data source or environment to take effect.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.Spacing.l)
            }

            RowDivider()
            InfoRow(label: "Endpoint", value: activeEnvironment.host, isMonospaced: false)
            RowDivider()
            InfoRow(label: "Organization", value: config.activeSnapshot.organizationId)
            RowDivider()
            InfoRow(label: "Profile", value: config.activeSnapshot.profileId)
            RowDivider()
            InfoRow(label: "Data source", value: config.activeSnapshot.dataSource)
            RowDivider()
            InfoRow(label: "App alias", value: config.activeSnapshot.appAlias)
        }
    }

    private var identityCard: some View {
        Card(title: "Identity", systemImage: "person.text.rectangle.fill",
             footnote: "cookieId is assigned by the SDK. exVisitorId is set through login / signUp on the Events tab.") {
            InfoRow(label: "cookieId", value: user.cookieId)
            RowDivider()
            InfoRow(label: "exVisitorId", value: user.exVisitorId)
            RowDivider()
            InfoRow(label: "tokenId", value: user.tokenId)
            RowDivider()
            InfoRow(label: "IDFA", value: user.identifierForAdvertising)
            RowDivider()
            ActionRow(title: "Request IDFA permission",
                      subtitle: "RelatedDigital.requestIDFA()",
                      systemImage: "hand.raised.fill") {
                RDLog.call("requestIDFA()", channel: .analytics)
                RelatedDigital.requestIDFA()
                toast.show("IDFA permission requested")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { refresh() }
            }
        }
    }

    private var sessionCard: some View {
        Card(title: "Session", systemImage: "clock.arrow.circlepath") {
            InfoRow(label: "Visit count", value: "\(user.tvc)", isMonospaced: false)
            RowDivider()
            InfoRow(label: "Page views", value: "\(user.pviv)", isMonospaced: false)
            RowDivider()
            InfoRow(label: "Last visit", value: user.lastVisit, isMonospaced: false)
            RowDivider()
            InfoRow(label: "App version", value: user.appVersion, isMonospaced: false)
            RowDivider()
            ActionRow(title: "Refresh", subtitle: "Re-read RelatedDigital.rdUser",
                      systemImage: "arrow.clockwise") {
                refresh()
                toast.show("Identity refreshed")
            }
        }
    }

    private var modulesCard: some View {
        Card(title: "Modules", systemImage: "switch.2",
             footnote: "These map directly onto the matching RelatedDigital static properties and apply immediately.") {
            SwitchRow(title: "In-app notifications",
                      subtitle: "RelatedDigital.inAppNotificationsEnabled",
                      isOn: $config.inAppNotificationsEnabled)
            RowDivider()
            SwitchRow(title: "Geofence",
                      subtitle: "RelatedDigital.geofenceEnabled",
                      isOn: $config.geofenceEnabled)
            RowDivider()
            SwitchRow(title: "SDK logging",
                      subtitle: "RelatedDigital.loggingEnabled",
                      isOn: $config.loggingEnabled)
        }
    }

    private var toolsCard: some View {
        Card(title: "Modules & tools", systemImage: "square.stack.3d.up.fill") {
            NavigationLink { EmbeddedWidgetsView() } label: {
                toolRow("Embedded widgets", "Story rail, banner carousel, NPS view", "rectangle.3.group.fill")
            }
            RowDivider()
            NavigationLink { RecommendationView() } label: {
                toolRow("Recommendation", "recommend() with filter builder", "wand.and.stars")
            }
            RowDivider()
            NavigationLink { FavoriteAttributesView() } label: {
                toolRow("Favorite attributes", "getFavoriteAttributeActions()", "heart.fill")
            }
            RowDivider()
            NavigationLink { GeofenceView() } label: {
                toolRow("Geofence", "Location state and server check history", "location.fill")
            }
            RowDivider()
            NavigationLink { SettingsView() } label: {
                toolRow("Settings", "Organization, profile, environment", "gearshape.fill")
            }
        }
    }

    private func toolRow(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
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

    // MARK: - Data

    private func refresh() {
        guard config.isSDKReady else { return }
        user = RDUserSnapshot(RelatedDigital.rdUser)
        push.refreshAuthorizationStatus()
        push.refreshToken()
    }
}

/// Plain value copy of `RDUser` so the view has something to diff against.
struct RDUserSnapshot {
    var cookieId = ""
    var exVisitorId = ""
    var tokenId = ""
    var identifierForAdvertising = ""
    var sdkVersion = "—"
    var appVersion = ""
    var lastVisit = ""
    var tvc = 0
    var pviv = 0

    init() {}

    init(_ user: RDUser) {
        cookieId = user.cookieId ?? ""
        exVisitorId = user.exVisitorId ?? ""
        tokenId = user.tokenId ?? ""
        identifierForAdvertising = user.identifierForAdvertising ?? ""
        sdkVersion = user.sdkVersion ?? "—"
        appVersion = user.appVersion ?? ""
        lastVisit = user.lvt ?? ""
        tvc = user.tvc
        pviv = user.pviv
    }
}
