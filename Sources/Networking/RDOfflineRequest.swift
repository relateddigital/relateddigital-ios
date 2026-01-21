//
//  RDOfflineRequest.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import Foundation

struct RDStoredRequest: Codable {
    let id: String
    let endpoint: String // We will store the full string endpoint or rely on reconstruction
    let method: String
    let headers: [String: String]
    let body: Data?
    let queryItems: [String: String]? // Storing query items as dictionary for simplicity in Codable
    let timestamp: Date
    let retryCount: Int
}

class RDRequestCache {
    private let storageKey = "RDOfflineRequests"
    private var limit = 1000 // Max requests to store
    
    // MARK: - Save
    
    func save(request: RDStoredRequest) {
        var requests = loadAll()
        // If limit reached, remove oldest
        if requests.count >= limit {
            requests.sort { $0.timestamp < $1.timestamp }
            if !requests.isEmpty {
                requests.removeFirst()
            }
        }
        requests.append(request)
        saveToDisk(requests)
    }
    
    // MARK: - Load
    
    func loadAll() -> [RDStoredRequest] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            let requests = try JSONDecoder().decode([RDStoredRequest].self, from: data)
            return requests
        } catch {
            RDLogger.error("Failed to decode offline requests: \(error)")
            return []
        }
    }
    
    // MARK: - Remove
    
    func remove(requestId: String) {
        var requests = loadAll()
        requests.removeAll { $0.id == requestId }
        saveToDisk(requests)
    }
    
    // MARK: - Private
    
    private func saveToDisk(_ requests: [RDStoredRequest]) {
        do {
            let data = try JSONEncoder().encode(requests)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            RDLogger.error("Failed to encode offline requests: \(error)")
        }
    }
}
