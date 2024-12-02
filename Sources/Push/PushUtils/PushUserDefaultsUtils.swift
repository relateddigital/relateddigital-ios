//
//  PushUserDefaultsUtils.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

class PushUserDefaultsUtils {
    // MARK: - UserDefaults

    static let userDefaults = UserDefaults(suiteName: PushKey.userDefaultSuiteKey)
    static var appGroupUserDefaults: UserDefaults?

    static func setAppGroupsUserDefaults(appGroupName: String) {
        appGroupUserDefaults = UserDefaults(suiteName: appGroupName)
    }

    static func retrieveUserDefaults(userKey: String) -> AnyObject? {
        var val: Any?
        if let value = appGroupUserDefaults?.object(forKey: userKey) {
            val = value
        } else if let value = userDefaults?.object(forKey: userKey) {
            val = value
        }
        guard let value = val else {
            return nil
        }
        return value as AnyObject?
    }

    static func removeUserDefaults(userKey: String) {
        if userDefaults?.object(forKey: userKey) != nil {
            userDefaults?.removeObject(forKey: userKey)
            userDefaults?.synchronize()
        }
        if appGroupUserDefaults?.object(forKey: userKey) != nil {
            appGroupUserDefaults?.removeObject(forKey: userKey)
            appGroupUserDefaults?.synchronize()
        }
    }

    static func saveUserDefaults(key: String?, value: AnyObject?) {
        guard key != nil && value != nil else {
            return
        }
        userDefaults?.set(value, forKey: key!)
        userDefaults?.synchronize()
        appGroupUserDefaults?.set(value, forKey: key!)
        appGroupUserDefaults?.synchronize()
    }

    // MARK: - Retention

    private static let pushIdLock = RDReadWriteLock(label: "PushIdLock")

    static func saveReadPushId(pushId: String) {
        var pushIdList = getReadPushIdList()
        pushIdLock.write {
            if !pushIdList.contains(pushId) {
                pushIdList.append(pushId)
                if let pushIdListData = try? JSONEncoder().encode(pushIdList) {
                    saveUserDefaults(key: PushKey.euroReadPushIdListKey, value: pushIdListData as AnyObject)
                } else {
                    RDLogger.warn("Can not encode pushIdList : \(String(describing: pushIdList))")
                }
            } else {
                RDLogger.warn("PushId already exists. pushId: \(pushId)")
            }
        }
    }

    static func savePayloadWithId(payload: RDPushMessage, notificationLoginID: String) {
        var payload = payload
        if let pushId = payload.pushId, !notificationLoginID.isEmpty {
            payload.notificationLoginID = notificationLoginID
            payload.formattedDateString = PushTools.formatDate(Date())
            payload.openedDate = ""
            payload.status = "D"
            if let extra = RDPush.shared?.subscription.extra {
                if extra["keyID"] != nil {
                    payload.keyID = extra["keyID"]
                }
                if extra["email"] != nil {
                    payload.email = extra["email"]
                }
            }
            var recentPayloads = getRecentPayloadsWithId()
            payloadLock.write {
                if let existingPayload = recentPayloads.first(where: { $0.pushId == pushId }) {
                    RDLogger.warn("Payload is not valid, there is already another payload with same pushId  New : \(payload.encode ?? "") Existing: \(existingPayload)")
                } else {
                    recentPayloads.insert(payload, at: 0)
                    if let recentPayloadsData = try? JSONEncoder().encode(recentPayloads) {
                        saveUserDefaults(key: PushKey.euroPayloadsWithIdKey, value: recentPayloadsData as AnyObject)
                    } else {
                        RDLogger.warn("Can not encode recentPayloads : \(String(describing: recentPayloads))")
                    }
                }
            }
        } else {
            RDLogger.warn("Payload is not valid, pushId missing : \(payload.encode ?? "")")
        }
    }

    static func deletePayloadWithId(pushId: String? = nil, completion: @escaping (Bool) -> Void) {
        let emptyPayloads: [RDPushMessage] = []
        var recentPayloads = getRecentPayloadsWithId()
        payloadLock.write {
            guard let pushId = pushId, let index = recentPayloads.firstIndex(where: { $0.pushId == pushId }) else {
                do {
                    let emptyData = try JSONEncoder().encode(emptyPayloads)
                    saveUserDefaults(key: PushKey.euroPayloadsWithIdKey, value: emptyData as AnyObject)
                    RDLogger.info("All payloads have been deleted successfully.")
                    completion(true)
                } catch {
                    RDLogger.warn("Cannot encode empty payloads: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }

            recentPayloads.remove(at: index)

            do {
                let updatedData = try JSONEncoder().encode(recentPayloads)
                saveUserDefaults(key: PushKey.euroPayloadsWithIdKey, value: updatedData as AnyObject)
                RDLogger.info("Push with id \(pushId) was deleted")
                completion(true)
            } catch {
                RDLogger.warn("Cannot encode recentPayloads after deletion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    static func deletePayload(pushId: String? = nil, completion: @escaping (Bool) -> Void) {
        let emptyPayloads: [RDPushMessage] = []
        var recentPayloads = getRecentPayloads()
        payloadLock.write {
            guard let pushId = pushId, let index = recentPayloads.firstIndex(where: { $0.pushId == pushId }) else {
                // PushId bulunamadı, tüm payload'ları temizliyoruz
                do {
                    let emptyData = try JSONEncoder().encode(emptyPayloads)
                    saveUserDefaults(key: PushKey.euroPayloadsKey, value: emptyData as AnyObject)
                    RDLogger.info("All payloads have been deleted successfully.")
                    completion(true)
                } catch {
                    RDLogger.warn("Cannot encode empty payloads: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }

            recentPayloads.remove(at: index)

            do {
                let updatedData = try JSONEncoder().encode(recentPayloads)
                saveUserDefaults(key: PushKey.euroPayloadsKey, value: updatedData as AnyObject)
                RDLogger.info("Push with id \(pushId) was deleted")
                completion(true)
            } catch {
                RDLogger.warn("Cannot encode recentPayloads after deletion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    static func getReadPushIdList() -> [String] {
        var finalPushIdList = [String]()
        pushIdLock.read {
            if let pushIdListJsonData = retrieveUserDefaults(userKey: PushKey.euroReadPushIdListKey) as? Data {
                if let pushIdList = try? JSONDecoder().decode([String].self, from: pushIdListJsonData) {
                    finalPushIdList = pushIdList
                }
            }
        }
        return Array(finalPushIdList.suffix(50))
    }

    static func pushIdListContains(pushId: String) -> Bool {
        return getReadPushIdList().contains(pushId)
    }

    // MARK: - Deliver

    private static let payloadLock = RDReadWriteLock(label: "PushPayloadLock")

    static func savePayload(payload: RDPushMessage) {
        var payload = payload
        if let pushId = payload.pushId {
            payload.formattedDateString = PushTools.formatDate(Date())
            payload.openedDate = ""
            payload.status = "D"
            if let extra = RDPush.shared?.subscription.extra {
                if let keyID = extra["keyID"] {
                    payload.keyID = keyID
                }
                if let email = extra["email"] {
                    payload.email = email
                }
            }
            var recentPayloads = getRecentPayloads()
            payloadLock.write {
                if let existingPayload = recentPayloads.first(where: { $0.pushId == pushId }) {
                    RDLogger.warn("Payload is not valid, there is already another payload with same pushId. New: \(payload.encode ?? ""), Existing: \(existingPayload)")
                } else {
                    recentPayloads.insert(payload, at: 0)
                    if let recentPayloadsData = try? JSONEncoder().encode(recentPayloads) {
                        saveUserDefaults(key: PushKey.euroPayloadsKey, value: recentPayloadsData as AnyObject)
                    } else {
                        RDLogger.warn("Cannot encode recentPayloads: \(String(describing: recentPayloads))")
                    }
                }
            }
        } else {
            RDLogger.warn("Payload is not valid, pushId missing: \(payload.encode ?? "")")
        }
    }

    static func updatePayload(pushId: String?) {
        var recentPayloads = getRecentPayloads()
        payloadLock.write {
            if let index = recentPayloads.firstIndex(where: { $0.pushId == pushId }) {
                var updatedPayload = recentPayloads[index]
                // Güncelleme işlemlerini yap
                updatedPayload.status = "O"
                updatedPayload.openedDate = PushTools.formatDate(Date())
                // Güncellenmiş payload'ı koleksiyona tekrar ekle
                recentPayloads[index] = updatedPayload
                if let updatedPayloadsData = try? JSONEncoder().encode(recentPayloads) {
                    saveUserDefaults(key: PushKey.euroPayloadsKey, value: updatedPayloadsData as AnyObject)
                } else {
                    RDLogger.warn("Can not encode updated payloads: \(String(describing: recentPayloads))")
                }
            } else {
                RDLogger.warn("Payload with pushId \(pushId ?? "") not found in recent payloads.")
            }
        }
    }

    static func readPushMessagesWithId(pushId: String? = nil, completion: @escaping (Bool) -> Void) {
        // Mevcut payload'ları al
        var recentPayloads = getRecentPayloadsWithId()

        payloadLock.write {
            guard let pushId = pushId, let index = recentPayloads.firstIndex(where: { $0.pushId == pushId }) else {
                do {
                    for index in 0 ..< recentPayloads.count {
                        recentPayloads[index].status = "O"
                        recentPayloads[index].openedDate = PushTools.formatDate(Date())
                    }

                    let updatedData = try JSONEncoder().encode(recentPayloads)
                    saveUserDefaults(key: PushKey.euroPayloadsWithIdKey, value: updatedData as AnyObject)
                    RDLogger.info("All messages marked as read")
                    completion(true)
                } catch {
                    RDLogger.warn("Push message with pushId \(pushId ?? "") not found.")
                    completion(false)
                }
                return
            }

            recentPayloads[index].status = "O"
            recentPayloads[index].openedDate = PushTools.formatDate(Date())

            do {
                let updatedData = try JSONEncoder().encode(recentPayloads)
                saveUserDefaults(key: PushKey.euroPayloadsWithIdKey, value: updatedData as AnyObject)
                RDLogger.info("Push with id \(pushId) marked as read")
                completion(true)
            } catch {
                RDLogger.warn("Cannot encode recentPayloads after deletion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    static func readPushMessages(pushId: String? = nil, completion: @escaping (Bool) -> Void) {
        // Mevcut payload'ları al
        var recentPayloads = getRecentPayloads()

        payloadLock.write {
            guard let pushId = pushId, let index = recentPayloads.firstIndex(where: { $0.pushId == pushId }) else {
                do {
                    for index in 0 ..< recentPayloads.count {
                        recentPayloads[index].status = "O"
                        recentPayloads[index].openedDate = PushTools.formatDate(Date())
                    }

                    let updatedData = try JSONEncoder().encode(recentPayloads)
                    saveUserDefaults(key: PushKey.euroPayloadsKey, value: updatedData as AnyObject)
                    RDLogger.info("All messages marked as read")
                    completion(true)
                } catch {
                    RDLogger.warn("Push message with pushId \(pushId ?? "") not found.")
                    completion(false)
                }
                return
            }

            recentPayloads[index].status = "O"
            recentPayloads[index].openedDate = PushTools.formatDate(Date())

            do {
                let updatedData = try JSONEncoder().encode(recentPayloads)
                saveUserDefaults(key: PushKey.euroPayloadsKey, value: updatedData as AnyObject)
                RDLogger.info("Push with id \(pushId) marked as read")
                completion(true)
            } catch {
                RDLogger.warn("Cannot encode recentPayloads after deletion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    static func getRecentPayloads() -> [RDPushMessage] {
        var finalPayloads = [RDPushMessage]()
        payloadLock.read {
            if let payloadsJsonData = retrieveUserDefaults(userKey: PushKey.euroPayloadsKey) as? Data {
                if let payloads = try? JSONDecoder().decode([RDPushMessage].self, from: payloadsJsonData) {
                    finalPayloads = payloads
                }
            }
            if let filterDate = Calendar.current.date(byAdding: .day, value: -PushKey.payloadDayThreshold, to: Date()) {
                finalPayloads = finalPayloads.filter({ payload in
                    if let date = payload.getDate() {
                        return date > filterDate
                    } else {
                        return false
                    }
                })
            }
        }
        return finalPayloads.sorted(by: { payload1, payload2 in
            if let date1 = payload1.getDate(), let date2 = payload2.getDate() {
                return date1 > date2
            } else {
                return false
            }
        })
    }

    static func getRecentPayloadsWithId() -> [RDPushMessage] {
        var finalPayloads = [RDPushMessage]()
        payloadLock.read {
            if let payloadsJsonData = retrieveUserDefaults(userKey: PushKey.euroPayloadsWithIdKey) as? Data {
                if let payloads = try? JSONDecoder().decode([RDPushMessage].self, from: payloadsJsonData) {
                    finalPayloads = payloads
                }
            }
            if let filterDate = Calendar.current.date(byAdding: .day, value: -PushKey.payloadDayThreshold, to: Date()) {
                finalPayloads = finalPayloads.filter({ payload in
                    if let date = payload.getDate() {
                        return date > filterDate
                    } else {
                        return false
                    }
                })
            }
        }
        return finalPayloads.sorted(by: { payload1, payload2 in
            if let date1 = payload1.getDate(), let date2 = payload2.getDate() {
                return date1 > date2
            } else {
                return false
            }
        })
    }

    static func payloadContains(pushId: String) -> Bool {
        let payloads = getRecentPayloads()
        return payloads.first(where: { $0.pushId == pushId }) != nil
    }

    // MARK: - Subscription

    private static let subscriptionLock = RDReadWriteLock(label: "EMSubscriptionLock")

    static func saveLastSuccessfulSubscriptionTime(time: Date) {
        subscriptionLock.write {
            saveUserDefaults(key: PushKey.euroLastSuccessfulSubscriptionDateKey, value: time as AnyObject)
        }
    }

    static func getLastSuccessfulSubscriptionTime() -> Date {
        var lastSuccessfulSubscriptionTime = Date(timeIntervalSince1970: 0)
        subscriptionLock.read {
            if let date = retrieveUserDefaults(userKey: PushKey.euroLastSuccessfulSubscriptionDateKey) as? Date {
                lastSuccessfulSubscriptionTime = date
            }
        }
        return lastSuccessfulSubscriptionTime
    }

    static func saveLastSuccessfulSubscription(subscription: PushSubscriptionRequest) {
        subscriptionLock.write {
            if let subscriptionData = try? JSONEncoder().encode(subscription) {
                saveUserDefaults(key: PushKey.euroLastSuccessfulSubscriptionKey, value: subscriptionData as AnyObject)
            } else {
                RDLogger.error("EMUserDefaultsUtils saveLastSuccessfulSubscription encode error.")
            }
        }
    }

    static func getLastSuccessfulSubscription() -> PushSubscriptionRequest? {
        var lastSuccessfulSubscription: PushSubscriptionRequest?
        subscriptionLock.read {
            if let lastSuccessfulSubscriptionData = retrieveUserDefaults(userKey: PushKey.euroLastSuccessfulSubscriptionKey) as? Data {
                if let subscription = try? JSONDecoder().decode(PushSubscriptionRequest.self, from: lastSuccessfulSubscriptionData) {
                    lastSuccessfulSubscription = subscription
                } else {
                    RDLogger.error("EMUserDefaultsUtils getLastSuccessfulSubscription decode error.")
                }
            }
        }
        return lastSuccessfulSubscription
    }
}
