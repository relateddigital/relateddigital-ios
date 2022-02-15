//
//  PushSubscriptionHandler.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushSubscriptionHandler {
    
    var push: Push!
    
    private let semaphore = DispatchSemaphore(value: 0)
    private let readWriteLock: PushReadWriteLock
    private var inProgressSubscriptionRequest: PushSubscriptionRequest?
    
    init(push: Push) {
        self.push = push
        self.readWriteLock = PushReadWriteLock(label: "PushSubscriptionHandler")
    }
    
    /// Reports user, device data and APNS token to RelatedDigital services
    /// - Parameters:
    ///   - subscription: Subscription data
    internal func reportSubscription(subscriptionRequest: PushSubscriptionRequest) {
        guard let _ = subscriptionRequest.appKey, let _ = subscriptionRequest.token else {
            PushLog.error("PushSubscriptionHandler reportSubscription appKey or token does not exist")
            return
        }
        
        var isRequestSame = false
        var isRequestSameAsLastSuccessfulSubscriptionRequest = false
        self.readWriteLock.read {
            if subscriptionRequest == inProgressSubscriptionRequest {
                isRequestSame = true
            }
            if let lastSuccessfulSubscriptionRequest = PushUserDefaultsUtils.getLastSuccessfulSubscription()
                , PushUserDefaultsUtils.getLastSuccessfulSubscriptionTime().addingTimeInterval(TimeInterval(PushKey.threeDaysInSeconds)) > Date()
                , lastSuccessfulSubscriptionRequest == subscriptionRequest {
                isRequestSameAsLastSuccessfulSubscriptionRequest = true
            }
        }
                
        if isRequestSame {
            PushLog.info("EMSubscriptionHandler request is not valid. EMSubscriptionRequest is the same as the previous one.")
            return
        }
        
        if isRequestSameAsLastSuccessfulSubscriptionRequest {
            PushLog.info("EMSubscriptionHandler request is not valid. EMSubscriptionRequest is the same as the lastSuccessfulSubscription.")
            return
        }
        
        self.readWriteLock.write {
            inProgressSubscriptionRequest = subscriptionRequest
            PushLog.info("EMSubscriptionHandler reportSubscription: \(subscriptionRequest.encoded)")
        }
        
        push.pushAPI?.request(requestModel: subscriptionRequest, retry: 3, completion: self.subscriptionRequestHandler)
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
    }
    
    private func subscriptionRequestHandler(result: Result<PushResponse?, PushAPIError>) {
        switch result {
        case .success:
            push.delegate?.didRegisterSuccessfully()
            if let subscriptionRequest = inProgressSubscriptionRequest {
                PushLog.success("PushSubscriptionHandler: Request successfully send, token: \(String(describing: subscriptionRequest.token))")
                PushUserDefaultsUtils.saveLastSuccessfulSubscriptionTime(time: Date())
                PushUserDefaultsUtils.saveLastSuccessfulSubscription(subscription: subscriptionRequest)
            }
        case .failure(let error):
            PushLog.error("EMSubscriptionHandler: Request failed : \(error)")
            push.delegate?.didFailRegister(error: error)
        }
        self.readWriteLock.write {
            inProgressSubscriptionRequest = nil
        }
        semaphore.signal()
    }
    
    
    
}

