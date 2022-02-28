//
//  RDLogger.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 23.11.2021.
//

import Foundation
import os.log

enum RDLogLevel: String {
    case debug = "▪️"
    case info = "🔷"
    case warning = "🔶"
    case error = "❌"
}

struct relatedDigitalLogMessage {
    /// The file where this log message was created
    let file: String

    /// The function where this log message was created
    let function: String

    /// The text of the log message
    let text: String

    /// The level of the log message
    let level: RDLogLevel

    init(path: String, function: String, text: String, level: RDLogLevel) {
        if let file = path.components(separatedBy: "/").last {
            self.file = file
        } else {
            self.file = path
        }
        self.function = function
        self.text = text
        self.level = level
    }
}

protocol RDLogging {
    func addMessage(message: relatedDigitalLogMessage)
}

class RDPrintLogging: RDLogging {
    func addMessage(message: relatedDigitalLogMessage) {
        let msg = "[Visilabs(\(message.level.rawValue))  - \(message.file) - func \(message.function)] : \(message.text)"
        os_log("%@", type: .debug, msg)
    }
}

class RDLogger {
    private static let readWriteLock: RDReadWriteLock = RDReadWriteLock(label: "RDLoggerLock")
    private static var enabledLevels = Set<RDLogLevel>()
    private static var loggers = [RDLogging]()

    class func addLogging(_ logging: RDLogging) {
        readWriteLock.write {
            if loggers.count > 0 {
                return
            }
            loggers.append(logging)
        }
    }

    class func enableLevels(_ levels: [RDLogLevel]) {
        readWriteLock.write {
            for level in levels {
                enabledLevels.insert(level)
            }
        }
    }

    class func disableLevels(_ levels: [RDLogLevel]) {
        readWriteLock.write {
            for level in levels {
                enabledLevels.remove(level)
            }
        }
    }

    class func debug(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
       var enabledLevels = Set<RDLogLevel>()
       readWriteLock.read {
           enabledLevels = self.enabledLevels
       }
       guard enabledLevels.contains(.debug) else { return }
       forwardLogMessage(relatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .debug))
   }

    class func info(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
       var enabledLevels = Set<RDLogLevel>()
       readWriteLock.read {
           enabledLevels = self.enabledLevels
       }
       guard enabledLevels.contains(.info) else { return }
       forwardLogMessage(relatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .info))
   }

    class func warn(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
       var enabledLevels = Set<RDLogLevel>()
       readWriteLock.read {
           enabledLevels = self.enabledLevels
       }
       guard enabledLevels.contains(.warning) else { return }
       forwardLogMessage(relatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .warning))
   }

   class func error(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
       var enabledLevels = Set<RDLogLevel>()
       readWriteLock.read {
           enabledLevels = self.enabledLevels
       }
       guard enabledLevels.contains(.error) else { return }
       forwardLogMessage(relatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .error))
   }

    class private func forwardLogMessage(_ message: relatedDigitalLogMessage) {
        var loggers = [RDLogging]()
        readWriteLock.read {
            loggers = self.loggers
        }
        loggers.forEach { $0.addMessage(message: message) }
    }

}
