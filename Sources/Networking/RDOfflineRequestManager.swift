//
//  RDOfflineRequestManager.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import Foundation

class RDOfflineRequestManager {
    static let shared = RDOfflineRequestManager()
    
    private let cache = RDRequestCache()
    private var isSending = false
    private var timer: Timer?
    
    // Allowed endpoints for offline storage
    private let offlineAllowedEndpoints = [
        RDConstants.loggerEndPoint,
        RDConstants.realtimeEndPoint
    ]
    
    private init() {
        startRetryTimer()
        // Try sending on init in case we have pending items
        processQueue()
    }
    
    deinit {
        stopRetryTimer()
    }
    
    // MARK: - Public API
    
    func queue(request: URLRequest, error: Error) {
        // Filter: Check if this request should be queued
        guard shouldQueue(request: request) else {
            RDLogger.info("Request not eligible for offline queue: \(request.url?.absoluteString ?? "")")
            return
        }
        
        // Convert URLRequest to RDStoredRequest
        let stored = mkStoredRequest(from: request)
        cache.save(request: stored)
        RDLogger.info("Offline request queued. Total in queue: \(cache.loadAll().count)")
    }
    
    // MARK: - Logic
    
    private func shouldQueue(request: URLRequest) -> Bool {
        guard let urlString = request.url?.absoluteString else { return false }
        
        // 1. Check strict endpoints (lgr and rt only)
        // Note: RDConstants.swift endpoints might just be domains or partial paths.
        // We need to check if the URL contains these allowed endpoints.
        
        // "s.visilabs.net" should be EXCLUDED (implicit if not in allowed list)
        
        for allowed in offlineAllowedEndpoints {
            if urlString.contains(allowed) {
                return true
            }
        }
        
        return false
    }
    
    private func mkStoredRequest(from request: URLRequest) -> RDStoredRequest {
        let headers = request.allHTTPHeaderFields ?? [:]
        let method = request.httpMethod ?? "GET"
        let body = request.httpBody
        let url = request.url?.absoluteString ?? ""
        
        // We try to extract query items if we can, but storing the full URL string might be safer/easier
        // if we just want to reconstruct it.
        // However, RDStoredRequest defines 'endpoint' and 'queryItems'.
        // Let's store the full URL in 'endpoint' for simplicity and ignore queryItems in reconstruction if 'endpoint' is full URL.
        
        return RDStoredRequest(id: UUID().uuidString,
                               endpoint: url,
                               method: method,
                               headers: headers,
                               body: body,
                               queryItems: nil,
                               timestamp: Date(),
                               retryCount: 0)
    }
    
    // MARK: - Processing
    
    @objc private func processQueue() {
        guard !isSending else { return }
        
        let requests = cache.loadAll()
        guard !requests.isEmpty else { return }
        
        // Pick the oldest
        let pending = requests.sorted { $0.timestamp < $1.timestamp }
        guard let nextRequest = pending.first else { return }
        
        isSending = true
        
        send(storedRequest: nextRequest) { [weak self] success in
            guard let self = self else { return }
            self.isSending = false
            
            if success {
                self.cache.remove(requestId: nextRequest.id)
                // Try next immediately
                self.processQueue()
            } else {
                // Failed again? Wait for next timer tick.
                // Optionally increment retry count and delete if too many.
            }
        }
    }
    
    private func send(storedRequest: RDStoredRequest, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: storedRequest.endpoint) else {
            completion(true) // Invalid URL, remove it
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = storedRequest.method
        urlRequest.httpBody = storedRequest.body
        
        for (key, val) in storedRequest.headers {
            urlRequest.setValue(val, forHTTPHeaderField: key)
        }
        
        // Important: Don't use RDNetwork.apiRequest here to avoid infinite loop of queuing!
        // Use URLSession directly.
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                RDLogger.error("Offline retry failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                RDLogger.info("Offline request sent successfully: \(url)")
                completion(true)
            } else {
                RDLogger.error("Offline retry failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                completion(false) // Server error, keep it? Or logic to remove 4xx, keep 5xx?
                // For now, keep it on error to retry later (hoping it's transient).
                // But if it's 400 (Bad Request), it will never succeed.
                
                if let httpResponse = response as? HTTPURLResponse, (400...499).contains(httpResponse.statusCode) {
                     // Client error, remove it.
                     completion(true)
                } else {
                     completion(false)
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Timer
    
    private func startRetryTimer() {
        // Try every 60 seconds
        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(processQueue), userInfo: nil, repeats: true)
    }
    
    private func stopRetryTimer() {
        timer?.invalidate()
        timer = nil
    }
}
