//
//  EventLog.swift
//  RelatedDigitalExample
//
//  In-app console. Every SDK call this app makes — and every callback it
//  receives — is recorded here instead of going to `print`, so the behaviour of
//  the SDK can be inspected on-device without attaching Xcode.
//

import Foundation
import SwiftUI

// MARK: - Model

struct LogEntry: Identifiable, Equatable {

    enum Kind: String, CaseIterable {
        case call       // outgoing SDK call
        case result     // successful response / callback
        case failure    // error returned by the SDK
        case info       // lifecycle & app-side notes

        var icon: String {
            switch self {
            case .call: return "arrow.up.right.circle.fill"
            case .result: return "arrow.down.left.circle.fill"
            case .failure: return "exclamationmark.octagon.fill"
            case .info: return "info.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .call: return Theme.accent
            case .result: return Theme.success
            case .failure: return Theme.danger
            case .info: return Theme.info
            }
        }
    }

    enum Channel: String, CaseIterable, Identifiable {
        case lifecycle = "Lifecycle"
        case analytics = "Analytics"
        case targeting = "Targeting"
        case push = "Push"
        case geofence = "Geofence"
        case recommendation = "Recommendation"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .lifecycle: return "power"
            case .analytics: return "chart.bar.fill"
            case .targeting: return "sparkles"
            case .push: return "bell.badge.fill"
            case .geofence: return "location.fill"
            case .recommendation: return "wand.and.stars"
            }
        }
    }

    let id = UUID()
    let date: Date
    var kind: Kind
    var channel: Channel
    var title: String
    var detail: String?

    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool { lhs.id == rhs.id }

    var timestamp: String { LogEntry.formatter.string(from: date) }

    /// Plain-text rendering used when exporting or copying the console.
    var plainText: String {
        var out = "[\(timestamp)] \(kind.rawValue.uppercased()) · \(channel.rawValue) · \(title)"
        if let detail, !detail.isEmpty { out += "\n\(detail)" }
        return out
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}

// MARK: - Store

@MainActor
final class EventLog: ObservableObject {

    static let shared = EventLog()

    private static let capacity = 500

    @Published private(set) var entries: [LogEntry] = []

    private init() {}

    // MARK: Recording

    func call(_ title: String, channel: LogEntry.Channel, payload: [String: String]? = nil) {
        append(.init(date: Date(), kind: .call, channel: channel,
                     title: title, detail: payload.flatMap(EventLog.render)))
    }

    func result(_ title: String, channel: LogEntry.Channel, detail: String? = nil) {
        append(.init(date: Date(), kind: .result, channel: channel, title: title, detail: detail))
    }

    func failure(_ title: String, channel: LogEntry.Channel, detail: String? = nil) {
        append(.init(date: Date(), kind: .failure, channel: channel, title: title, detail: detail))
    }

    func info(_ title: String, channel: LogEntry.Channel = .lifecycle, detail: String? = nil) {
        append(.init(date: Date(), kind: .info, channel: channel, title: title, detail: detail))
    }

    func clear() { entries.removeAll() }

    var exportText: String {
        entries.reversed().map(\.plainText).joined(separator: "\n\n")
    }

    // MARK: Helpers

    /// Sorted `key = value` rendering so payloads diff cleanly between runs.
    static func render(_ payload: [String: String]) -> String {
        payload
            .sorted { $0.key < $1.key }
            .map { "\($0.key) = \($0.value)" }
            .joined(separator: "\n")
    }

    private func append(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > EventLog.capacity {
            entries.removeLast(entries.count - EventLog.capacity)
        }
    }
}

/// Convenience so call sites read as `RDLog.call(...)`.
@MainActor
enum RDLog {
    static func call(_ title: String, channel: LogEntry.Channel, payload: [String: String]? = nil) {
        EventLog.shared.call(title, channel: channel, payload: payload)
    }

    static func result(_ title: String, channel: LogEntry.Channel, detail: String? = nil) {
        EventLog.shared.result(title, channel: channel, detail: detail)
    }

    static func failure(_ title: String, channel: LogEntry.Channel, detail: String? = nil) {
        EventLog.shared.failure(title, channel: channel, detail: detail)
    }

    static func info(_ title: String, channel: LogEntry.Channel = .lifecycle, detail: String? = nil) {
        EventLog.shared.info(title, channel: channel, detail: detail)
    }
}
