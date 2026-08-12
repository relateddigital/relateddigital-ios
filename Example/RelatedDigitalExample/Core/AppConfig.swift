//
//  AppConfig.swift
//  RelatedDigitalExample
//
//  Persisted configuration for the sample app.
//
//  `RelatedDigital.initialize` can only be called once per process, so the
//  values that actually reached the SDK are snapshotted at launch
//  (`activeSnapshot`). Anything edited afterwards is marked as pending and the
//  UI tells the tester a relaunch is required.
//
//  Production and test credentials are stored side by side: `UrlConstant.setTest()`
//  only swaps the ids held inside the SDK, while `initialize` receives whatever
//  this object passes it. Keeping one credential set per environment means the
//  two can never drift apart, and edits made in one environment survive a
//  round trip through the other.
//

import Foundation
import RelatedDigitalIOS

/// Which Related Digital backend the sample app talks to.
enum SDKEnvironment: String, CaseIterable {

    case production
    case test

    var displayName: String {
        switch self {
        case .production: return "Production"
        case .test: return "Test"
        }
    }

    /// Host the SDK resolves its endpoints against, for display only.
    var host: String {
        switch self {
        case .production: return "s.visilabs.net"
        case .test: return "tests.visilabs.net"
        }
    }

    /// Demo credentials shipped with the sample. These mirror the values
    /// `UrlConstant` holds for each environment.
    var defaults: Credentials {
        switch self {
        case .production:
            return Credentials(organizationId: "676D325830564761676D453D",
                               profileId: "356467332F6533766975593D",
                               dataSource: "visistore")
        case .test:
            return Credentials(organizationId: "394A48556A2F76466136733D",
                               profileId: "75763259366A3345686E303D",
                               dataSource: "mhrp")
        }
    }
}

struct Credentials: Equatable {
    var organizationId: String
    var profileId: String
    var dataSource: String
}

@MainActor
final class AppConfig: ObservableObject {

    static let shared = AppConfig()

    // MARK: - Environment

    /// Routes the SDK at the test backend. Backed by the SDK's own `UrlConstant`
    /// flag so it survives relaunches, and swaps the active credential set.
    @Published var useTestEnvironment: Bool {
        didSet {
            guard oldValue != useTestEnvironment else { return }
            UrlConstant.shared.setTestWithLocalData(isActive: useTestEnvironment)

            // Swapping the credentials touches three more @Published properties.
            // Doing that synchronously inside this didSet publishes changes while
            // SwiftUI is still applying the toggle's binding write, which makes it
            // discard the write and snap back. Defer to the next tick instead.
            let target = environment
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.applyCredentials(self.storedCredentials(for: target))
                RDLog.info("Environment switched to \(target.displayName)",
                           detail: EventLog.render([
                            "host": target.host,
                            "organizationId": self.organizationId,
                            "profileId": self.profileId,
                            "dataSource": self.dataSource
                           ]))
            }
        }
    }

    var environment: SDKEnvironment { useTestEnvironment ? .test : .production }

    // MARK: - Per-environment credentials

    @Published var organizationId: String { didSet { persistCredentials() } }
    @Published var profileId: String { didSet { persistCredentials() } }
    @Published var dataSource: String { didSet { persistCredentials() } }

    /// True when the active credentials still match the shipped demo values.
    var isUsingDefaultCredentials: Bool {
        Credentials(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
            == environment.defaults
    }

    // MARK: - Shared settings

    @Published var appAlias: String { didSet { persist(appAlias, .appAlias) } }
    @Published var appGroupsKey: String { didSet { persist(appGroupsKey, .appGroupsKey) } }
    @Published var exVisitorId: String { didSet { persist(exVisitorId, .exVisitorId) } }
    @Published var email: String { didSet { persist(email, .email) } }

    @Published var inAppNotificationsEnabled: Bool {
        didSet {
            persist(inAppNotificationsEnabled, .inAppNotificationsEnabled)
            guard isSDKReady else { return }
            RelatedDigital.inAppNotificationsEnabled = inAppNotificationsEnabled
            RDLog.info("inAppNotificationsEnabled = \(inAppNotificationsEnabled)")
        }
    }

    @Published var geofenceEnabled: Bool {
        didSet {
            persist(geofenceEnabled, .geofenceEnabled)
            guard isSDKReady else { return }
            RelatedDigital.geofenceEnabled = geofenceEnabled
            RDLog.info("geofenceEnabled = \(geofenceEnabled)")
        }
    }

    @Published var loggingEnabled: Bool {
        didSet {
            persist(loggingEnabled, .loggingEnabled)
            guard isSDKReady else { return }
            RelatedDigital.loggingEnabled = loggingEnabled
            RDLog.info("loggingEnabled = \(loggingEnabled)")
        }
    }

    @Published var askLocationPermissionAtStart: Bool {
        didSet { persist(askLocationPermissionAtStart, .askLocationPermissionAtStart) }
    }

    // MARK: - Launch snapshot

    /// Values that were handed to `RelatedDigital.initialize` this session.
    private(set) var activeSnapshot = Snapshot()
    private(set) var isSDKReady = false

    struct Snapshot: Equatable {
        var organizationId = ""
        var profileId = ""
        var dataSource = ""
        var appAlias = ""
        var useTestEnvironment = false
    }

    var currentSnapshot: Snapshot {
        Snapshot(organizationId: organizationId,
                 profileId: profileId,
                 dataSource: dataSource,
                 appAlias: appAlias,
                 useTestEnvironment: useTestEnvironment)
    }

    /// True when the edited configuration no longer matches what the SDK booted with.
    var needsRelaunch: Bool { isSDKReady && currentSnapshot != activeSnapshot }

    func markInitialized() {
        isSDKReady = true
        activeSnapshot = currentSnapshot
    }

    // MARK: - Init

    private init() {
        let d = UserDefaults.standard
        let isTest = UrlConstant.shared.getTestWithLocalData()
        let environment: SDKEnvironment = isTest ? .test : .production
        let credentials = AppConfig.storedCredentials(for: environment, in: d)

        useTestEnvironment = isTest
        organizationId = credentials.organizationId
        profileId = credentials.profileId
        dataSource = credentials.dataSource

        appAlias = d.string(forKey: Key.appAlias.rawValue) ?? "RDIOSExample"
        appGroupsKey = d.string(forKey: Key.appGroupsKey.rawValue)
            ?? "group.com.relateddigital.RelatedDigitalExample.relateddigital"
        exVisitorId = d.string(forKey: Key.exVisitorId.rawValue) ?? "userKey"
        email = d.string(forKey: Key.email.rawValue) ?? "user@mail.com"
        inAppNotificationsEnabled = d.object(forKey: Key.inAppNotificationsEnabled.rawValue) as? Bool ?? true
        geofenceEnabled = d.object(forKey: Key.geofenceEnabled.rawValue) as? Bool ?? true
        loggingEnabled = d.object(forKey: Key.loggingEnabled.rawValue) as? Bool ?? true
        askLocationPermissionAtStart = d.object(forKey: Key.askLocationPermissionAtStart.rawValue) as? Bool ?? false
    }

    // MARK: - Resetting

    /// Restores the credentials of the active environment to the shipped demo values.
    func restoreEnvironmentDefaults() {
        applyCredentials(environment.defaults)
        RDLog.info("\(environment.displayName) credentials restored to demo defaults")
    }

    /// Restores every value — both environments included — to the shipped defaults.
    func resetToDefaults() {
        let d = UserDefaults.standard
        Key.allCases.forEach { d.removeObject(forKey: $0.rawValue) }
        SDKEnvironment.allCases.forEach { environment in
            CredentialKey.allCases.forEach { key in
                d.removeObject(forKey: key.storageKey(for: environment))
            }
        }
        UrlConstant.shared.setTestWithLocalData(isActive: false)

        useTestEnvironment = false
        applyCredentials(SDKEnvironment.production.defaults)
        appAlias = "RDIOSExample"
        appGroupsKey = "group.com.relateddigital.RelatedDigitalExample.relateddigital"
        exVisitorId = "userKey"
        email = "user@mail.com"
        inAppNotificationsEnabled = true
        geofenceEnabled = true
        loggingEnabled = true
        askLocationPermissionAtStart = false
    }

    // MARK: - Credential storage

    private func applyCredentials(_ credentials: Credentials) {
        organizationId = credentials.organizationId
        profileId = credentials.profileId
        dataSource = credentials.dataSource
    }

    private func storedCredentials(for environment: SDKEnvironment) -> Credentials {
        AppConfig.storedCredentials(for: environment, in: .standard)
    }

    private static func storedCredentials(for environment: SDKEnvironment,
                                          in defaults: UserDefaults) -> Credentials {
        let shipped = environment.defaults
        return Credentials(
            organizationId: defaults.string(forKey: CredentialKey.organizationId.storageKey(for: environment))
                ?? shipped.organizationId,
            profileId: defaults.string(forKey: CredentialKey.profileId.storageKey(for: environment))
                ?? shipped.profileId,
            dataSource: defaults.string(forKey: CredentialKey.dataSource.storageKey(for: environment))
                ?? shipped.dataSource
        )
    }

    private func persistCredentials() {
        let d = UserDefaults.standard
        d.set(organizationId, forKey: CredentialKey.organizationId.storageKey(for: environment))
        d.set(profileId, forKey: CredentialKey.profileId.storageKey(for: environment))
        d.set(dataSource, forKey: CredentialKey.dataSource.storageKey(for: environment))
    }

    private enum CredentialKey: String, CaseIterable {
        case organizationId, profileId, dataSource

        func storageKey(for environment: SDKEnvironment) -> String {
            "cfg.\(environment.rawValue).\(rawValue)"
        }
    }

    private enum Key: String, CaseIterable {
        case appAlias = "cfg.appAlias"
        case appGroupsKey = "cfg.appGroupsKey"
        case exVisitorId = "cfg.exVisitorId"
        case email = "cfg.email"
        case inAppNotificationsEnabled = "cfg.inAppNotificationsEnabled"
        case geofenceEnabled = "cfg.geofenceEnabled"
        case loggingEnabled = "cfg.loggingEnabled"
        case askLocationPermissionAtStart = "cfg.askLocationPermissionAtStart"
    }

    private func persist(_ value: Any, _ key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
