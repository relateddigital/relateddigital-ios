//
//  RelatedDigitalLogger.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation
import os.log

enum RelatedDigitalLogLevel: String {
    case debug = "▪️"
    case info = "🔷"
    case warning = "🔶"
    case error = "❌"
}

struct RelatedDigitalLogMessage {
    let file: String
    let function: String
    let text: String
    let level: RelatedDigitalLogLevel
    
    init(path: String, function: String, text: String, level: RelatedDigitalLogLevel) {
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

class RelatedDigitalLogger {
    private static let readWriteLock: RelatedDigitalWriteLock = RelatedDigitalWriteLock(label: "relatedDigitalLoggerLock")
    private static var enabledLevels = Set<RelatedDigitalLogLevel>()
    
    class func enableLevel(_ level: RelatedDigitalLogLevel) {
        readWriteLock.write {
            enabledLevels.insert(level)
        }
    }
    
    class func disableLevel(_ level: RelatedDigitalLogLevel) {
        readWriteLock.write {
            enabledLevels.remove(level)
        }
    }
    
    class func debug(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
        var enabledLevels = Set<RelatedDigitalLogLevel>()
        readWriteLock.read {
            enabledLevels = self.enabledLevels
        }
        guard enabledLevels.contains(.debug) else { return }
        log(RelatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .debug))
    }
    
    class func info(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
        var enabledLevels = Set<RelatedDigitalLogLevel>()
        readWriteLock.read {
            enabledLevels = self.enabledLevels
        }
        guard enabledLevels.contains(.info) else { return }
        log(RelatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .info))
    }
    
    class func warn(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
        var enabledLevels = Set<RelatedDigitalLogLevel>()
        readWriteLock.read {
            enabledLevels = self.enabledLevels
        }
        guard enabledLevels.contains(.warning) else { return }
        log(RelatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .warning))
    }
    
    class func error(_ message: @autoclosure() -> Any, _ path: String = #file, _ function: String = #function) {
        var enabledLevels = Set<RelatedDigitalLogLevel>()
        readWriteLock.read {
            enabledLevels = self.enabledLevels
        }
        guard enabledLevels.contains(.error) else { return }
        log(RelatedDigitalLogMessage(path: path, function: function, text: "\(message())", level: .error))
    }
    
    class private func log(_ message: RelatedDigitalLogMessage) {
        DispatchQueue.main.async {
            //TODO: burayı düşün os_log vs debugPrint vs print
            debugPrint("[RelatedDigital(\(message.level.rawValue)) - \(Date().format()) - \(message.file) - func \(message.function)] : \(message.text)")
        }
    }
}

/* TODO: subsystem ve category ne işe yarıyor incele
extension OSLog {
    public static let dispatching = OSLog(subsystem: "io.rover", category: "Routing")
    public static let general = OSLog(subsystem: "io.rover", category: "General")
}
*/
