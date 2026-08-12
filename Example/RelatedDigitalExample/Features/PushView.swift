//
//  PushView.swift
//  RelatedDigitalExample
//
//  Push module: OS permission, subscription attributes, user properties and the
//  locally stored message inbox.
//

import RelatedDigitalIOS
import SwiftUI

struct PushView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var push: PushCenter
    @EnvironmentObject private var toast: ToastCenter

    @State private var pushPermission = false
    @State private var gsmPermission = false
    @State private var emailPermission = false

    @State private var email = ""
    @State private var msisdn = ""
    @State private var propertyKey = ""
    @State private var propertyValue = ""
    @State private var badgeCount = "0"

    var body: some View {
        Screen(title: "Push",
               subtitle: "Permissions, subscription attributes and the delivered-message store.") {

            permissionCard
            tokenCard
            subscriptionCard
            userPropertyCard
            inboxCard
            maintenanceCard
        }
        .onAppear {
            email = config.email
            push.refreshAuthorizationStatus()
            push.refreshToken()
        }
    }

    // MARK: - Permission

    private var permissionCard: some View {
        Card(title: "Authorization", systemImage: "bell.badge.fill",
             footnote: "Provisional authorization delivers quietly to the notification center without prompting the user.") {
            HStack(spacing: Theme.Spacing.s) {
                Pill(text: push.statusText, tint: push.statusTint, systemImage: "bell.fill")
                Spacer(minLength: 0)
                Button {
                    push.refreshAuthorizationStatus()
                    push.refreshToken()
                    toast.show("Status refreshed", icon: "arrow.clockwise", tint: Theme.info)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.m)

            RowDivider()
            ActionRow(title: "Ask for permission",
                      subtitle: "askForNotificationPermission(register: true)",
                      systemImage: "hand.raised.fill") {
                RDLog.call("askForNotificationPermission(register: true)", channel: .push)
                RelatedDigital.askForNotificationPermission(register: true)
                toast.show("Permission requested")
                refreshStatusShortly()
            }
            RowDivider()
            ActionRow(title: "Ask provisionally",
                      subtitle: "askForNotificationPermissionProvisional(register: true)",
                      systemImage: "hand.raised.circle") {
                RDLog.call("askForNotificationPermissionProvisional(register: true)", channel: .push)
                RelatedDigital.askForNotificationPermissionProvisional(register: true)
                toast.show("Provisional permission requested")
                refreshStatusShortly()
            }
            RowDivider()
            ActionRow(title: "Open system settings",
                      subtitle: "Change the decision the user already made",
                      systemImage: "gear",
                      tint: Theme.info,
                      showsChevron: true) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Token

    private var tokenCard: some View {
        Card(title: "Device token", systemImage: "key.fill",
             footnote: "On the simulator remote registration never completes, so a placeholder token is registered instead.") {
            InfoRow(label: "Token", value: push.token, placeholder: "not registered")
            RowDivider()
            ActionRow(title: "Register for push notifications",
                      subtitle: "registerForPushNotifications()",
                      systemImage: "arrow.up.circle.fill") {
                #if targetEnvironment(simulator)
                RDLog.call("registerToken(tokenData:) — simulator placeholder", channel: .push)
                RelatedDigital.registerToken(tokenData: Data(base64Encoded: "dG9rZW4="))
                toast.show("Placeholder token registered", icon: "key.fill", tint: Theme.warning)
                #else
                RDLog.call("registerForPushNotifications()", channel: .push)
                RelatedDigital.registerForPushNotifications()
                toast.show("Registration requested")
                #endif
                refreshStatusShortly()
            }
            RowDivider()
            ActionRow(title: "Read token from SDK",
                      subtitle: "getToken(completion:)",
                      systemImage: "arrow.down.circle.fill") {
                RDLog.call("getToken()", channel: .push)
                RelatedDigital.getToken { token in
                    Task { @MainActor in
                        token.isEmpty
                            ? RDLog.failure("getToken → empty", channel: .push)
                            : RDLog.result("getToken", channel: .push, detail: token)
                        push.refreshToken()
                        toast.show(token.isEmpty ? "No token stored" : "Token read")
                    }
                }
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionCard: some View {
        Card(title: "Subscription", systemImage: "person.crop.circle.badge.checkmark",
             footnote: "Permissions are queued locally; `sync()` flushes them to the subscription endpoint.") {
            SwitchRow(title: "Push permission", subtitle: "setPushNotification(permission:)", isOn: $pushPermission)
                .onChange(of: pushPermission) { value in
                    RDLog.call("setPushNotification(permission: \(value))", channel: .push)
                    RelatedDigital.setPushNotification(permission: value)
                }
            RowDivider()
            SwitchRow(title: "GSM permission", subtitle: "setPhoneNumber(permission:)", isOn: $gsmPermission)
                .onChange(of: gsmPermission) { value in
                    RDLog.call("setPhoneNumber(permission: \(value))", channel: .push)
                    RelatedDigital.setPhoneNumber(msisdn: msisdn.isEmpty ? nil : msisdn, permission: value)
                }
            RowDivider()
            SwitchRow(title: "Email permission", subtitle: "setEmail(permission:)", isOn: $emailPermission)
                .onChange(of: emailPermission) { value in
                    RDLog.call("setEmail(permission: \(value))", channel: .push)
                    RelatedDigital.setEmail(email: email.isEmpty ? nil : email, permission: value)
                }
            RowDivider()
            FieldRow(label: "Email", placeholder: "user@mail.com", text: $email, keyboard: .emailAddress)
            RowDivider()
            FieldRow(label: "Phone", placeholder: "+90…", text: $msisdn, keyboard: .phonePad)
            RowDivider()
            ActionRow(title: "Save and sync",
                      subtitle: "setEmail(email:permission:) + setPhoneNumber + sync()",
                      systemImage: "arrow.triangle.2.circlepath") {
                let payload = [
                    "email": email,
                    "emailPermission": "\(emailPermission)",
                    "msisdn": msisdn,
                    "gsmPermission": "\(gsmPermission)"
                ]
                RDLog.call("setEmail + setPhoneNumber + sync()", channel: .push, payload: payload)
                if !email.isEmpty {
                    RelatedDigital.setEmail(email: email, permission: emailPermission)
                    config.email = email
                }
                if !msisdn.isEmpty {
                    RelatedDigital.setPhoneNumber(msisdn: msisdn, permission: gsmPermission)
                }
                RelatedDigital.sync()
                toast.show("Subscription synced")
            }
        }
    }

    // MARK: - User properties

    private var userPropertyCard: some View {
        Card(title: "User properties", systemImage: "list.bullet.rectangle.fill",
             footnote: "Keys map to the subscription payload fields shown in the Related Digital panel.") {
            FieldRow(label: "Key", placeholder: "e.g. city", text: $propertyKey)
            RowDivider()
            FieldRow(label: "Value", placeholder: "e.g. Istanbul", text: $propertyValue)
            RowDivider()
            ActionRow(title: "Set property",
                      subtitle: "setUserProperty(key:value:) + sync()",
                      systemImage: "plus.circle.fill",
                      isEnabled: !propertyKey.trimmed.isEmpty) {
                let key = propertyKey.trimmed
                RDLog.call("setUserProperty", channel: .push,
                           payload: ["key": key, "value": propertyValue])
                RelatedDigital.setUserProperty(key: key, value: propertyValue)
                RelatedDigital.sync()
                toast.show("Property set")
            }
            RowDivider()
            ActionRow(title: "Remove property",
                      subtitle: "removeUserProperty(key:) + sync()",
                      systemImage: "minus.circle.fill",
                      tint: Theme.danger,
                      isEnabled: !propertyKey.trimmed.isEmpty) {
                let key = propertyKey.trimmed
                RDLog.call("removeUserProperty", channel: .push, payload: ["key": key])
                RelatedDigital.removeUserProperty(key: key)
                RelatedDigital.sync()
                toast.show("Property removed")
            }
        }
    }

    // MARK: - Inbox

    private var inboxCard: some View {
        Card(title: "Message store", systemImage: "tray.full.fill",
             footnote: "Delivered payloads are persisted by the notification service extension into the shared app group.") {
            HStack(spacing: Theme.Spacing.s) {
                Button {
                    push.loadMessages()
                } label: {
                    inboxButtonLabel("Load messages", count: push.messages.count)
                }
                .buttonStyle(.plain)

                Button {
                    push.loadMessagesWithId()
                } label: {
                    inboxButtonLabel("With ID", count: push.messagesWithId.count)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.m)

            let combined = push.messages.isEmpty ? push.messagesWithId : push.messages

            if push.isLoadingMessages {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, Theme.Spacing.xl)
            } else if combined.isEmpty {
                RowDivider()
                EmptyState(systemImage: "tray",
                           title: "No stored messages",
                           message: "Send a push to this device, then load the store again.")
            } else {
                ForEach(Array(combined.enumerated()), id: \.offset) { _, message in
                    RowDivider()
                    NavigationLink { PushMessageDetailView(message: message) } label: {
                        messageRow(message)
                    }
                }
            }
        }
    }

    private func inboxButtonLabel(_ title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(Theme.accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private func messageRow(_ message: RDPushMessage) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(message.aps?.alert?.title ?? "Untitled")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(message.formattedDateString ?? "—")  ·  \(message.pushId ?? "no id")")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
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

    // MARK: - Maintenance

    private var maintenanceCard: some View {
        Card(title: "Maintenance", systemImage: "wrench.and.screwdriver.fill") {
            FieldRow(label: "Badge count", placeholder: "0", text: $badgeCount, keyboard: .numberPad)
            RowDivider()
            ActionRow(title: "Set badge", subtitle: "setBadge(count:)", systemImage: "app.badge.fill") {
                let count = Int(badgeCount) ?? 0
                RDLog.call("setBadge(count: \(count))", channel: .push)
                RelatedDigital.setBadge(count: count)
                toast.show("Badge set to \(count)")
            }
            RowDivider()
            ActionRow(title: "Mark all as read",
                      subtitle: "readPushMessages(pushId: nil)",
                      systemImage: "envelope.open.fill") {
                push.markRead(pushId: nil)
                toast.show("Marked as read")
            }
            RowDivider()
            ActionRow(title: "Clear message store",
                      subtitle: "deleteNotifications()",
                      systemImage: "trash.fill",
                      tint: Theme.danger) {
                push.deleteAll()
                toast.show("Message store cleared", icon: "trash.fill", tint: Theme.danger)
            }
        }
    }

    // MARK: - Helpers

    private func refreshStatusShortly() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            push.refreshAuthorizationStatus()
            push.refreshToken()
        }
    }
}

// MARK: - Message detail

struct PushMessageDetailView: View {

    let message: RDPushMessage

    @EnvironmentObject private var push: PushCenter
    @EnvironmentObject private var toast: ToastCenter

    var body: some View {
        Screen(title: "Message") {
            Card(title: "Summary", systemImage: "envelope.fill") {
                InfoRow(label: "Push ID", value: message.pushId)
                RowDivider()
                InfoRow(label: "Date", value: message.formattedDateString, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Title", value: message.aps?.alert?.title, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Body", value: message.aps?.alert?.body, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Status", value: message.status, isMonospaced: false)
                RowDivider()
                InfoRow(label: "Deep link", value: message.deeplink ?? message.url)
                RowDivider()
                InfoRow(label: "Media", value: message.mediaUrl)
            }

            if let source = message.utm_source ?? message.utm_campaign {
                Card(title: "Campaign", systemImage: "megaphone.fill") {
                    InfoRow(label: "utm_source", value: message.utm_source ?? source, isMonospaced: false)
                    RowDivider()
                    InfoRow(label: "utm_medium", value: message.utm_medium, isMonospaced: false)
                    RowDivider()
                    InfoRow(label: "utm_campaign", value: message.utm_campaign, isMonospaced: false)
                }
            }

            if let json = message.encode {
                Card(title: "Raw payload", systemImage: "curlybraces") {
                    PayloadBlock(text: json, maxHeight: 320)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.m)
                }
            }

            if let pushId = message.pushId, !pushId.isEmpty {
                Card(title: "Actions", systemImage: "bolt.fill") {
                    ActionRow(title: "Mark as read",
                              subtitle: "readPushMessages(pushId:)",
                              systemImage: "envelope.open.fill") {
                        push.markRead(pushId: pushId)
                        toast.show("Marked as read")
                    }
                    RowDivider()
                    ActionRow(title: "Remove from store",
                              subtitle: "removeNotification(withPushID:)",
                              systemImage: "trash.fill",
                              tint: Theme.danger) {
                        push.remove(pushId: pushId)
                        toast.show("Removal requested", icon: "trash.fill", tint: Theme.danger)
                    }
                }
            }
        }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
