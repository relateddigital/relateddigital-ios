//
//  PushAPI.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushReadHandler {
    private let readWriteLock: RDReadWriteLock
    var push: RDPush!
    private var inProgressPushId: String?
    private var inProgressEmPushSp: String?
    private var pushMessage: RDPushMessage?
    
    
    init(push: RDPush) {
        self.push = push
        self.readWriteLock = RDReadWriteLock(label: "PushReadHandler")
    }
    
    // MARK: Report Methods
    
    /// Reports recieved push to RelatedDigital services
    /// - Parameters:
    ///   - message: Push data
    internal func reportRead(message: RDPushMessage) {
        
        guard let appKey = push.subscription.appKey, let token = push.subscription.token else {
            RDLogger.error("EMReadHandler reportRead appKey or token does not exist")
            return
        }
        
        var request: PushRetentionRequest?
        
        guard let pushID = message.pushId, let emPushSp = message.emPushSp else {
            RDLogger.warn("EMReadHandler pushId or emPushSp is empty.")
            return
        }
        
        if PushUserDefaultsUtils.pushIdListContains(pushId: pushID) {
            RDLogger.warn("EMReadHandler pushId already sent.")
            return
        }
        
        var isRequestValid = true
        
        self.readWriteLock.read {
            if pushID == inProgressPushId && emPushSp == inProgressEmPushSp  {
                isRequestValid = false
            }
        }
        
        if !isRequestValid {
            RDLogger.warn("EMReadHandler request not valid. Retention request with pushId: \(pushID) and emPushSp \(emPushSp) already sent.")
            return
        }
        
        self.readWriteLock.write {
            self.inProgressPushId = pushID
            self.inProgressEmPushSp = emPushSp
            self.pushMessage = message
            RDLogger.info("reportRead: \(message)")
            request = PushRetentionRequest(key: appKey, token: token, status: PushKey.euroReadStatus, pushId: pushID, emPushSp: emPushSp)
        }
        
        if let request = request {
            self.push.pushAPI?.request(requestModel: request, retry: 3, completion: self.readRequestHandler)
        }
    }
    
    private func readRequestHandler(result: Result<PushResponse?, PushAPIError>) {
        switch result {
        case .success:
            PushUserDefaultsUtils.removeUserDefaults(userKey: PushKey.euroLastMessageKey)
            if let pushId = inProgressPushId {
                PushUserDefaultsUtils.saveReadPushId(pushId: pushId)
            }
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
    
    /// Controls locale storage for unreported changes on user data
    internal func checkUserUnreportedMessages() {
        let messageJson = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.euroLastMessageKey) as? Data
        if let messageJson = messageJson {
            RDLogger.info("Old message : \(messageJson)")
            let lastMessage = try? JSONDecoder().decode(RDPushMessage.self, from: messageJson)
            if let lastMessage = lastMessage {
                reportRead(message: lastMessage)
            }
        }
    }
}
