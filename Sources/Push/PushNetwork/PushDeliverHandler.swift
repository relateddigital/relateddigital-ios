//
//  PushDeliverHandler.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushDeliverHandler {
    private let readWriteLock: RDReadWriteLock
    var push: RDPush!
    private var inProgressPushId: String?
    private var inProgressEmPushSp: String?
    private var pushMessage: RDPushMessage?
    
    
    init(push: RDPush) {
        self.push = push
        self.readWriteLock = RDReadWriteLock(label: "PushDeliverHandler")
    }
        
    /// Reports delivered push to RelatedDigital services
    /// - Parameters:
    ///   - message: Push data
    internal func reportDeliver(message: RDPushMessage) {
        guard let appKey = push.subscription.appKey, let token = push.subscription.token else {
            RDLogger.error("EMDeliverHandler reportDeliver appKey or token does not exist")
            return
        }
        
        var request: PushRetentionRequest?
        
        guard let pushID = message.pushId, let emPushSp = message.emPushSp else {
            RDLogger.warn("EMDeliverHandler pushId or emPushSp is empty")
            return
        }
        
        if PushUserDefaultsUtils.payloadContains(pushId: pushID) {
            RDLogger.warn("EMDeliverHandler pushId already sent.")
            return
        }
        
        var isRequestValid = true
        
        self.readWriteLock.read {
            if pushID == inProgressPushId && emPushSp == inProgressEmPushSp  {
                isRequestValid = false
            }
        }
        
        if !isRequestValid {
            RDLogger.warn("EMDeliverHandler request not valid. Retention request with pushId: \(pushID) and emPushSp \(emPushSp) already sent.")
            return
        }
        
        self.readWriteLock.write {
            self.inProgressPushId = pushID
            self.inProgressEmPushSp = emPushSp
            self.pushMessage = message
            RDLogger.info("reportDeliver: \(message.encode ?? "")")
            request = PushRetentionRequest(key: appKey, token: token, status: PushKey.euroReceivedStatus, pushId: pushID, emPushSp: emPushSp)
        }
        
        if let request = request {
            self.push.pushAPI?.request(requestModel: request, retry: 3, completion: self.deliverRequestHandler)
        }
    }
    
    private func deliverRequestHandler(result: Result<PushResponse?, PushAPIError>) {
        switch result {
        case .success:
            PushUserDefaultsUtils.removeUserDefaults(userKey: PushKey.euroLastMessageKey)
        case .failure:
            if let pushMessage = pushMessage, let pushMessageData = try? JSONEncoder().encode(pushMessage) {
                PushUserDefaultsUtils.saveUserDefaults(key: PushKey.euroLastMessageKey, value: pushMessageData as AnyObject)
            }
            self.readWriteLock.write {
                self.inProgressPushId = nil
                self.inProgressEmPushSp = nil
                self.pushMessage = nil
            }
        }
    }
}
