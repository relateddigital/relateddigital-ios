//
//  PushCenter.swift
//  RelatedDigitalExample
//
//  Observable mirror of the push state: OS authorization, the token the SDK
//  currently holds, and the locally stored message inbox.
//

import Foundation
import RelatedDigitalIOS
import SwiftUI
import UserNotifications

@MainActor
final class PushCenter: ObservableObject {

    static let shared = PushCenter()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var token: String = ""
    @Published private(set) var messages: [RDPushMessage] = []
    @Published private(set) var messagesWithId: [RDPushMessage] = []
    @Published private(set) var isLoadingMessages = false

    private init() {}

    // MARK: - Status

    var statusText: String {
        switch authorizationStatus {
        case .notDetermined: return "Not determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    var statusTint: Color {
        switch authorizationStatus {
        case .authorized: return Theme.success
        case .provisional, .ephemeral: return Theme.warning
        case .denied: return Theme.danger
        default: return Theme.textTertiary
        }
    }

    func refreshAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }
    }

    func refreshToken() {
        RelatedDigital.getToken { [weak self] token in
            Task { @MainActor in self?.token = token }
        }
    }

    // MARK: - Inbox

    func loadMessages() {
        isLoadingMessages = true
        RDLog.call("getPushMessages()", channel: .push)
        RelatedDigital.getPushMessages { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages
                self?.isLoadingMessages = false
                RDLog.result("getPushMessages → \(messages.count) message(s)", channel: .push,
                             detail: messages.isEmpty ? nil : PushCenter.summary(of: messages))
            }
        }
    }

    func loadMessagesWithId() {
        isLoadingMessages = true
        RDLog.call("getPushMessagesWithID()", channel: .push)
        RelatedDigital.getPushMessagesWithID { [weak self] messages in
            Task { @MainActor in
                self?.messagesWithId = messages
                self?.isLoadingMessages = false
                RDLog.result("getPushMessagesWithID → \(messages.count) message(s)", channel: .push,
                             detail: messages.isEmpty ? nil : PushCenter.summary(of: messages))
            }
        }
    }

    func deleteAll() {
        RDLog.call("deleteNotifications()", channel: .push)
        RelatedDigital.deleteNotifications()
        messages = []
        messagesWithId = []
        RDLog.result("Local push store cleared", channel: .push)
    }

    func remove(pushId: String) {
        RDLog.call("removeNotification(withPushID:)", channel: .push, payload: ["pushId": pushId])
        RelatedDigital.removeNotification(withPushID: pushId) { [weak self] removed in
            Task { @MainActor in
                if removed {
                    RDLog.result("Notification removed", channel: .push, detail: "pushId = \(pushId)")
                    self?.loadMessages()
                } else {
                    RDLog.failure("Notification could not be removed", channel: .push,
                                  detail: "pushId = \(pushId)")
                }
            }
        }
    }

    func markRead(pushId: String?) {
        RDLog.call("readPushMessages(pushId:)", channel: .push, payload: ["pushId": pushId ?? "all"])
        RelatedDigital.readPushMessages(pushId: pushId) { success in
            Task { @MainActor in
                success
                    ? RDLog.result("Message marked as read", channel: .push)
                    : RDLog.failure("Message could not be marked as read", channel: .push)
            }
        }
    }

    private static func summary(of messages: [RDPushMessage]) -> String {
        messages.enumerated().map { index, message in
            """
            [\(index + 1)] pushId = \(message.pushId ?? "nil")
                date    = \(message.formattedDateString ?? "nil")
                title   = \(message.aps?.alert?.title ?? "nil")
            """
        }.joined(separator: "\n")
    }
}
