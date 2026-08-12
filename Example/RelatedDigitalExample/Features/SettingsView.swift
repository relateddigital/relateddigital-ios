//
//  SettingsView.swift
//  RelatedDigitalExample
//
//  Everything that is handed to `RelatedDigital.initialize`, editable and
//  persisted. Changes here need a relaunch, which the screen makes explicit.
//

import RelatedDigitalIOS
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var toast: ToastCenter

    @State private var isShowingResetConfirmation = false

    var body: some View {
        Screen(title: "Settings",
               subtitle: "Values used at launch. `initialize` runs once per process.") {

            if config.needsRelaunch {
                relaunchBanner
            }

            Card(title: "\(config.environment.displayName) credentials",
                 systemImage: "building.2.fill",
                 footnote: "Each environment keeps its own credential set, so switching back and forth never mixes them up. Obtain these from the Related Digital panel under Management → User Management → Profiles.") {
                HStack(spacing: Theme.Spacing.s) {
                    Pill(text: config.environment.host,
                         tint: config.useTestEnvironment ? Theme.warning : Theme.info,
                         systemImage: "network")
                    if config.isUsingDefaultCredentials {
                        Pill(text: "Demo defaults", tint: Theme.textTertiary, systemImage: "checkmark")
                    } else {
                        Pill(text: "Edited", tint: Theme.accent, systemImage: "pencil")
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.m)

                RowDivider()
                FieldRow(label: "Organization", placeholder: "organizationId", text: $config.organizationId)
                RowDivider()
                FieldRow(label: "Profile", placeholder: "profileId", text: $config.profileId)
                RowDivider()
                FieldRow(label: "Data source",
                         placeholder: config.environment.defaults.dataSource,
                         text: $config.dataSource)
                RowDivider()
                ActionRow(title: "Restore \(config.environment.displayName.lowercased()) demo credentials",
                          subtitle: "Only affects this environment",
                          systemImage: "arrow.counterclockwise",
                          isEnabled: !config.isUsingDefaultCredentials) {
                    config.restoreEnvironmentDefaults()
                    toast.show("\(config.environment.displayName) credentials restored")
                }
            }

            Card(title: "Push", systemImage: "bell.fill",
                 footnote: "The app group must match the one shared with the NotificationService and NotificationContent extensions.") {
                FieldRow(label: "App alias", placeholder: "RDIOSExample", text: $config.appAlias)
                RowDivider()
                FieldRow(label: "App group", placeholder: "group.…", text: $config.appGroupsKey)
            }

            Card(title: "Environment", systemImage: "network",
                 footnote: "Switching swaps both the endpoint and the credential set above. Takes effect on the next launch.") {
                SwitchRow(title: "Use test environment",
                          subtitle: config.environment.host,
                          isOn: $config.useTestEnvironment)
                RowDivider()
                SwitchRow(title: "Ask location permission at start",
                          subtitle: "Passed to initialize(askLocationPermmissionAtStart:)",
                          isOn: $config.askLocationPermissionAtStart)
            }

            Card(title: "Location", systemImage: "location.fill") {
                ActionRow(title: "Request location permission",
                          subtitle: "RelatedDigital.requestLocationPermissions()",
                          systemImage: "location.circle.fill") {
                    RDLog.call("requestLocationPermissions()", channel: .geofence)
                    RelatedDigital.requestLocationPermissions()
                    toast.show("Location permission requested")
                }
                RowDivider()
                ActionRow(title: "Send location permission state",
                          subtitle: "RelatedDigital.sendLocationPermission()",
                          systemImage: "paperplane.fill") {
                    RDLog.call("sendLocationPermission()", channel: .geofence)
                    RelatedDigital.sendLocationPermission()
                    toast.show("Location permission sent")
                }
            }

            Card(title: "Reset", systemImage: "arrow.counterclockwise") {
                ActionRow(title: "Restore defaults",
                          subtitle: "Clears saved settings for this app only",
                          systemImage: "trash.fill",
                          tint: Theme.danger) {
                    isShowingResetConfirmation = true
                }
            }
        }
        .confirmationDialog("Restore default settings?",
                            isPresented: $isShowingResetConfirmation,
                            titleVisibility: .visible) {
            Button("Restore defaults", role: .destructive) {
                config.resetToDefaults()
                toast.show("Settings restored")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Organization, profile, push and environment settings return to the values shipped with the sample. The SDK keeps running with the current configuration until you relaunch.")
        }
    }

    private var relaunchBanner: some View {
        Banner(title: "Relaunch required",
               message: "The SDK is still running with the previous configuration. Fully quit and reopen the app to apply the changes.",
               systemImage: "arrow.triangle.2.circlepath",
               tint: Theme.warning)
    }
}
