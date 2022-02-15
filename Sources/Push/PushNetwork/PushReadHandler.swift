//
//  PushAPI.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushReadHandler {
    private let readWriteLock: PushReadWriteLock
    var push: Push!
    private var inProgressPushId: String?
    private var inProgressEmPushSp: String?
    private var pushMessage: PushMessage?
    
    
    init(push: Push) {
        self.push = push
        self.readWriteLock = PushReadWriteLock(label: "PushReadHandler")
    }
    
    // MARK: Report Methods
    
    /// Reports recieved push to RelatedDigital services
    /// - Parameters:
    ///   - message: Push data
    internal func reportRead(message: PushMessage) {
        
        guard let appKey = push.subscription.appKey, let token = push.subscription.token else {
            PushLog.error("EMReadHandler reportRead appKey or token does not exist")
            return
        }
        
        var request: PushRetentionRequest?
        
        guard let pushID = message.pushId, let emPushSp = message.emPushSp else {
            PushLog.warning("EMReadHandler pushId or emPushSp is empty.")
            return
        }
        
        if PushUserDefaultsUtils.pushIdListContains(pushId: pushID) {
            PushLog.warning("EMReadHandler pushId already sent.")
            return
        }
        
        var isRequestValid = true
        
        self.readWriteLock.read {
            if pushID == inProgressPushId && emPushSp == inProgressEmPushSp  {
                isRequestValid = false
            }
        }
        
        if !isRequestValid {
            PushLog.warning("EMReadHandler request not valid. Retention request with pushId: \(pushID) and emPushSp \(emPushSp) already sent.")
            return
        }
        
        self.readWriteLock.write {
            inProgressPushId = pushID
            inProgressEmPushSp = emPushSp
            pushMessage = message
            PushLog.info("reportRead: \(message.encoded)")
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
                inProgressPushId = nil
                inProgressEmPushSp = nil
                pushMessage = nil
            }
        }
    }
    
    /// Controls locale storage for unreported changes on user data
    internal func checkUserUnreportedMessages() {
        let messageJson = PushUserDefaultsUtils.retrieveUserDefaults(userKey: PushKey.euroLastMessageKey) as? Data
        if let messageJson = messageJson {
            PushLog.info("Old message : \(messageJson)")
            let lastMessage = try? JSONDecoder().decode(PushMessage.self, from: messageJson)
            if let lastMessage = lastMessage {
                reportRead(message: lastMessage)
            }
        }
    }
}
