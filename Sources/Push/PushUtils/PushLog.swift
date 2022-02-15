//
//  PushLog.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 10.02.2022.
//

import Foundation
import os.log

class PushLog {

    /// shared instance
    static var shared = PushLog()

    private init() {}

    /// is Logging enable
    static var isEnabled: Bool = true

    /// Log for success. Will add 🟢 emoji to see better
    ///
    /// - Parameter message: Logging message
    static func success(_ message: Any!) {
        PushLog.shared.debug(type: "🟢", message: message)
    }

    /// Log for success. Will add 🔵 emoji to see better
    ///
    /// - Parameter message: Logging message
    static func info(_ message: Any) {
        PushLog.shared.debug(type: "🔵", message: message)
    }

    /// Log for warning. Will add ⚠️ emoji to see better
    ///
    /// - Parameter message: Logging message
    static func warning(_ message: Any) {
        PushLog.shared.debug(type: "⚠️", message: message)
    }

    /// Log for error. Will add 🔴 emoji to see better
    ///
    /// - Parameter message: Logging message
    static func error(_ message: Any) {
        PushLog.shared.debug(type: "🔴", message: message)
    }

    private func debug(type: Any?, message: Any?) {
        guard PushLog.isEnabled else { return }
        DispatchQueue.main.async {
            os_log("%@", type: .debug, "\(type ?? "") -> \(message ?? "")")
        }
    }

}
