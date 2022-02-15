//
//  PushDeliverHandler.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushDeliverHandler {
    private let readWriteLock: PushReadWriteLock
    var push: Push!
    private var inProgressPushId: String?
    private var inProgressEmPushSp: String?
    private var pushMessage: PushMessage?
    
    
    init(push: Push) {
        self.push = push
        self.readWriteLock = PushReadWriteLock(label: "PushDeliverHandler")
    }
        
    /// Reports delivered push to RelatedDigital services
    /// - Parameters:
    ///   - message: Push data
    internal func reportDeliver(message: PushMessage) {
        guard let appKey = push.subscription.appKey, let token = push.subscription.token else {
            PushLog.error("EMDeliverHandler reportDeliver appKey or token does not exist")
            return
        }
        
        var request: PushRetentionRequest?
        
        guard let pushID = message.pushId, let emPushSp = message.emPushSp else {
            PushLog.warning("EMDeliverHandler pushId or emPushSp is empty")
            return
        }
        
        if PushUserDefaultsUtils.payloadContains(pushId: pushID) {
            PushLog.warning("EMDeliverHandler pushId already sent.")
            return
        }
        
        var isRequestValid = true
        
        self.readWriteLock.read {
            if pushID == inProgressPushId && emPushSp == inProgressEmPushSp  {
                isRequestValid = false
            }
        }
        
        if !isRequestValid {
            PushLog.warning("EMDeliverHandler request not valid. Retention request with pushId: \(pushID) and emPushSp \(emPushSp) already sent.")
            return
        }
        
        self.readWriteLock.write {
            inProgressPushId = pushID
            inProgressEmPushSp = emPushSp
            pushMessage = message
            PushLog.info("reportDeliver: \(message.encoded)")
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
                inProgressPushId = nil
                inProgressEmPushSp = nil
                pushMessage = nil
            }
        }
    }
}
