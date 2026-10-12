//
//  RDCaptureQueue.swift
//  RelatedDigitalIOS
//

import Foundation

/// Diske yazılan event kuyruğu. Her event `<uuidv7>.json` olarak saklanır (UUIDv7 zaman
/// sıralı olduğu için dosya adı sırası = event sırası). Uygulama kapanınca veya internet
/// yokken event kaybolmaz; `/batch/` endpoint'ine toplu gönderilir.
///
/// Tüm metotlar `RDCapture`'ın seri kuyruğundan çağrılmalı.
final class RDCaptureQueue {

    static let host = "https://event.visilabs.net"
    static let batchPath = "/batch/"

    /// Bu kadar event birikince beklemeden gönderilir.
    static let flushAt = 20
    /// Kuyrukta bekleyen event'ler en geç bu sürede gönderilir.
    static let flushInterval: TimeInterval = 10
    static let maxBatchSize = 50
    static let maxQueueSize = 1000
    static let maxRetryDelay: TimeInterval = 5 * 60

    var apiKey: String?

    private let dispatchQueue: DispatchQueue
    private let session: URLSession
    private let directory: URL?
    private var fileNames = [String]()
    private var isFlushing = false
    private var retryCount = 0
    private var pausedUntil: Date?
    private var timer: DispatchSourceTimer?
    private var pendingCompletions = [() -> Void]()

    init(dispatchQueue: DispatchQueue, session: URLSession? = nil, directory: URL? = RDCaptureQueue.defaultDirectory()) {
        self.dispatchQueue = dispatchQueue
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: configuration)
        }
        self.directory = directory
        loadFileNames()
    }

    var count: Int { fileNames.count }

    func startTimer() {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        timer.schedule(deadline: .now() + RDCaptureQueue.flushInterval,
                       repeating: RDCaptureQueue.flushInterval)
        timer.setEventHandler { [weak self] in self?.flush() }
        timer.resume()
        self.timer = timer
    }

    func add(_ event: [String: Any]) {
        guard let directory = directory, let uuid = event["uuid"] as? String,
              let data = try? JSONSerialization.data(withJSONObject: event) else {
            RDLogger.error("capture: event kuyruğa yazılamadı: \(event["event"] ?? "")")
            return
        }

        while fileNames.count >= RDCaptureQueue.maxQueueSize {
            RDLogger.warn("capture: kuyruk dolu, en eski event siliniyor.")
            deleteFiles([fileNames[0]])
        }

        let fileName = "\(uuid).json"
        do {
            try data.write(to: directory.appendingPathComponent(fileName), options: .atomic)
            fileNames.append(fileName)
        } catch {
            RDLogger.error("capture: event diske yazılamadı: \(error)")
            return
        }

        if fileNames.count >= RDCaptureQueue.flushAt {
            flush()
        }
    }

    /// `completion` gönderim bittiğinde (başarılı ya da başarısız) seri kuyrukta çağrılır.
    func flush(completion: (() -> Void)? = nil) {
        if let completion = completion {
            pendingCompletions.append(completion)
        }
        guard !isFlushing else { return }
        guard let apiKey = apiKey, !apiKey.isEmpty, !fileNames.isEmpty,
              pausedUntil.map({ Date() >= $0 }) ?? true else {
            finishFlush()
            return
        }

        let batchFileNames = Array(fileNames.prefix(RDCaptureQueue.maxBatchSize))
        var events = [[String: Any]]()
        var unreadable = [String]()
        for fileName in batchFileNames {
            if let directory = directory,
               let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)),
               let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                events.append(event)
            } else {
                unreadable.append(fileName)
            }
        }
        deleteFiles(unreadable)

        guard !events.isEmpty, let url = URL(string: RDCaptureQueue.host + RDCaptureQueue.batchPath) else {
            finishFlush()
            return
        }

        let body: [String: Any] = [
            "api_key": apiKey,
            "batch": events,
            "sent_at": RDCaptureUtils.iso8601String(Date())
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            RDLogger.error("capture: batch JSON'a çevrilemedi, event'ler siliniyor.")
            deleteFiles(batchFileNames)
            finishFlush()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(RDCaptureContext.libName)/\(RDConstants.sdkVersion)", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData

        RDLogger.debug("capture: \(events.count) event gönderiliyor\n\(RDCaptureQueue.prettyJSON(body))")

        isFlushing = true
        let sentFileNames = batchFileNames.filter { !unreadable.contains($0) }
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.dispatchQueue.async {
                self.handleResponse(statusCode: (response as? HTTPURLResponse)?.statusCode,
                                    data: data, error: error, fileNames: sentFileNames)
            }
        }.resume()
    }

    private func handleResponse(statusCode: Int?, data: Data?, error: Error?, fileNames sentFileNames: [String]) {
        isFlushing = false
        let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

        if let statusCode = statusCode, (200..<300).contains(statusCode) {
            RDLogger.info("capture: \(sentFileNames.count) event gönderildi.")
            deleteFiles(sentFileNames)
            retryCount = 0
            pausedUntil = nil
            // Kuyrukta hala event varsa devam et.
            if !fileNames.isEmpty {
                flush()
                return
            }
        } else if statusCode == nil || statusCode == 408 || statusCode == 429 || (statusCode ?? 0) >= 500 {
            // Ağ hatası / sunucu hatası: event'ler kuyrukta kalır, artan beklemeyle tekrar denenir.
            retryCount += 1
            let delay = min(RDCaptureQueue.flushInterval * pow(2, Double(retryCount - 1)),
                            RDCaptureQueue.maxRetryDelay)
            pausedUntil = Date().addingTimeInterval(delay)
            RDLogger.warn("capture: gönderim başarısız (\(statusCode.map(String.init) ?? error?.localizedDescription ?? "")), \(Int(delay)) sn sonra tekrar denenecek. \(responseBody)")
        } else {
            // 400 vb.: tekrar denemek sonucu değiştirmez, event'ler atılır.
            RDLogger.error("capture: HTTP \(statusCode ?? -1), \(sentFileNames.count) event atıldı. \(responseBody)")
            deleteFiles(sentFileNames)
            retryCount = 0
            pausedUntil = nil
        }
        finishFlush()
    }

    private func finishFlush() {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0() }
    }

    private func deleteFiles(_ names: [String]) {
        guard !names.isEmpty else { return }
        let nameSet = Set(names)
        if let directory = directory {
            for name in names {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            }
        }
        fileNames.removeAll { nameSet.contains($0) }
    }

    private func loadFileNames() {
        guard let directory = directory else { return }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        fileNames = names.filter { $0.hasSuffix(".json") }.sorted()
    }

    private static func prettyJSON(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func defaultDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        var directory = base.appendingPathComponent("com.relateddigital.relateddigitalios/capture-queue", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? directory.setResourceValues(values)
        } catch {
            RDLogger.error("capture: kuyruk klasörü oluşturulamadı: \(error)")
            return nil
        }
        return directory
    }
}
