//
//  VisilabsPersistence.swift
//  VisilabsIOS
//
//  Created by Egemen on 15.04.2020.
//

import Foundation

public class RelatedDigitalPersistence {

    // MARK: - ARCHIVE

    private static let archiveQueueUtility = DispatchQueue(label: "com.relateddigital.archiveQueue", qos: .utility)

    private class func filePath(filename: String) -> String? {
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        guard let urlUnwrapped = url?.appendingPathComponent(filename).path else {
            return nil
        }
        return urlUnwrapped
    }

    class func archiveUser(_ relatedDigitalUser: RelatedDigitalUser) {
        archiveQueueUtility.sync { [relatedDigitalUser] in
            let propertiesFilePath = filePath(filename: RelatedDigitalConstants.userArchiveKey)
            guard let path = propertiesFilePath else {
                RelatedDigitalLogger.error("bad file path, cant fetch file")
                return
            }
            var userDic = [String: String?]()
            userDic[RelatedDigitalConstants.cookieIdKey] = relatedDigitalUser.cookieId
            userDic[RelatedDigitalConstants.exvisitorIdKey] = relatedDigitalUser.exVisitorId
            userDic[RelatedDigitalConstants.appidKey] = relatedDigitalUser.appId
            userDic[RelatedDigitalConstants.tokenIdKey] = relatedDigitalUser.tokenId
            userDic[RelatedDigitalConstants.userAgentKey] = relatedDigitalUser.userAgent
            userDic[RelatedDigitalConstants.visitorCappingKey] = relatedDigitalUser.visitorData
            userDic[RelatedDigitalConstants.visitorData] = relatedDigitalUser.visitorData
            userDic[RelatedDigitalConstants.mobileIdKey] = relatedDigitalUser.identifierForAdvertising
            userDic[RelatedDigitalConstants.mobileSdkVersion] = relatedDigitalUser.sdkVersion
            userDic[RelatedDigitalConstants.mobileAppVersion] = relatedDigitalUser.appVersion
            
            userDic[RelatedDigitalConstants.lastEventTimeKey] = relatedDigitalUser.lastEventTime
            userDic[RelatedDigitalConstants.nrvKey] = String(relatedDigitalUser.nrv)
            userDic[RelatedDigitalConstants.pvivKey] = String(relatedDigitalUser.pviv)
            userDic[RelatedDigitalConstants.tvcKey] = String(relatedDigitalUser.tvc)
            userDic[RelatedDigitalConstants.lvtKey] = relatedDigitalUser.lvt
            
            if !NSKeyedArchiver.archiveRootObject(userDic, toFile: path) {
                RelatedDigitalLogger.error("failed to archive user")
            }
        }
    }

    // TO_DO: bunu ExceptionWrapper içine al
    // swiftlint:disable cyclomatic_complexity
    class func unarchiveUser() -> RelatedDigitalUser {
        var relatedDigitalUser = RelatedDigitalUser()
        // Before Visilabs.identity is used as archive key, to retrieve Visilabs.cookieID set by objective-c library
        // we added this control.
        if let cidfp = filePath(filename: RelatedDigitalConstants.identityArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            relatedDigitalUser.cookieId = cid
        }
        if let cidfp = filePath(filename: RelatedDigitalConstants.cookieidArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            relatedDigitalUser.cookieId = cid
        }
        if let exvidfp = filePath(filename: RelatedDigitalConstants.exvisitorIdArchiveKey),
           let exvid = NSKeyedUnarchiver.unarchiveObject(withFile: exvidfp) as? String {
            relatedDigitalUser.exVisitorId = exvid
        }
        if let appidfp = filePath(filename: RelatedDigitalConstants.appidArchiveKey),
           let aid = NSKeyedUnarchiver.unarchiveObject(withFile: appidfp) as? String {
            relatedDigitalUser.appId = aid
        }
        if let tidfp = filePath(filename: RelatedDigitalConstants.tokenidArchiveKey),
           let tid = NSKeyedUnarchiver.unarchiveObject(withFile: tidfp) as? String {
            relatedDigitalUser.tokenId = tid
        }
        if let uafp = filePath(filename: RelatedDigitalConstants.useragentArchiveKey),
           let userAgent = NSKeyedUnarchiver.unarchiveObject(withFile: uafp) as? String {
            relatedDigitalUser.userAgent = userAgent
        }

        if let propsfp = filePath(filename: RelatedDigitalConstants.userArchiveKey),
           let props = NSKeyedUnarchiver.unarchiveObject(withFile: propsfp) as? [String: String?] {
            if let cid = props[RelatedDigitalConstants.cookieIdKey], !cid.isNilOrWhiteSpace {
                relatedDigitalUser.cookieId = cid
            }
            if let exvid = props[RelatedDigitalConstants.exvisitorIdKey], !exvid.isNilOrWhiteSpace {
                relatedDigitalUser.exVisitorId = exvid
            }
            if let aid = props[RelatedDigitalConstants.appidKey], !aid.isNilOrWhiteSpace {
                relatedDigitalUser.appId = aid
            }
            if let tid = props[RelatedDigitalConstants.tokenIdKey], !tid.isNilOrWhiteSpace {
                relatedDigitalUser.tokenId = tid
            }
            if let userAgent = props[RelatedDigitalConstants.userAgentKey], !userAgent.isNilOrWhiteSpace {
                relatedDigitalUser.userAgent = userAgent
            }
            if let visitorData = props[RelatedDigitalConstants.visitorData], !visitorData.isNilOrWhiteSpace {
                relatedDigitalUser.visitorData = visitorData
            }
            // TO_DO: visilabsUserda ya üstteki kod gereksiz ya da alttaki yanlış
            if let visitorData = props[RelatedDigitalConstants.visitorCappingKey], !visitorData.isNilOrWhiteSpace {
                relatedDigitalUser.visitorData = visitorData
            }
            if let madid = props[RelatedDigitalConstants.mobileIdKey], !madid.isNilOrWhiteSpace {
                relatedDigitalUser.identifierForAdvertising = madid
            }
            if let sdkversion = props[RelatedDigitalConstants.mobileSdkVersion], !sdkversion.isNilOrWhiteSpace {
                relatedDigitalUser.sdkVersion = sdkversion
            }
            if let appversion = props[RelatedDigitalConstants.mobileAppVersion], !appversion.isNilOrWhiteSpace {
                relatedDigitalUser.appVersion = appversion
            }
            if let lastEventTime = props[RelatedDigitalConstants.lastEventTimeKey] as? String {
                relatedDigitalUser.lastEventTime = lastEventTime
            }
            if let nrvString = props[RelatedDigitalConstants.nrvKey] as? String, let nrv = Int(nrvString)  {
                relatedDigitalUser.nrv = nrv
            }
            if let pvivString = props[RelatedDigitalConstants.pvivKey] as? String, let pviv = Int(pvivString)  {
                relatedDigitalUser.pviv = pviv
            }
            if let tvcString = props[RelatedDigitalConstants.tvcKey] as? String, let tvc = Int(tvcString)  {
                relatedDigitalUser.tvc = tvc
            }
            if let lvt = props[RelatedDigitalConstants.lvtKey] as? String {
                relatedDigitalUser.lvt = lvt
            }
        } else {
            RelatedDigitalLogger.warn("Visilabs: Error while unarchiving properties.")
        }
        return relatedDigitalUser
    }

    static func getDateStr() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    // TO_DO: burada date kısmı yanlış geliyor sanki
    // TO_DO: buradaki encode işlemleri doğru mu kontrol et;
    // archiveQueue.sync { yerine archiveQueue.sync {[parameters] in
    class func saveTargetParameters(_ parameters: [String: String]) {
        archiveQueueUtility.sync {
            let dateString = getDateStr()
            var targetParameters = readTargetParameters()

            for relatedDigitalParameter in RelatedDigitalConstants.relatedDigitalTargetParameters() {
                let key = relatedDigitalParameter.key
                let storeKey = relatedDigitalParameter.storeKey
                let relatedKeys = relatedDigitalParameter.relatedKeys
                let count = relatedDigitalParameter.count
                if let parameterValue = parameters[key], parameterValue.count > 0 {
                    if count == 1 {
                        if relatedKeys != nil && relatedKeys!.count > 0 {
                            var parameterValueToStore = parameterValue.copy() as? String ?? ""
                            let relatedKey = relatedKeys![0]
                            if parameters[relatedKey] != nil {
                                let relatedKeyValue = (parameters[relatedKey])?
                                    .trimmingCharacters(in: CharacterSet.whitespaces)
                                parameterValueToStore += ("|")
                                parameterValueToStore += (relatedKeyValue ?? "")
                            } else { parameterValueToStore += ("|0") }
                            parameterValueToStore += "|" + dateString
                            targetParameters[storeKey] = parameterValueToStore
                        } else {
                            targetParameters[storeKey] = parameterValue
                        }
                    } else if count > 1 {
                        let previousParameterValue = targetParameters[storeKey]
                        var parameterValueToStore = (parameterValue.copy() as? String ?? "") + ("|")
                        parameterValueToStore += (dateString)
                        if previousParameterValue != nil && previousParameterValue!.count > 0 {
                            let previousParameterValueParts = previousParameterValue!.components(separatedBy: "~")
                            for counter in 0..<previousParameterValueParts.count {
                                if counter == 9 {
                                    break
                                }
                                let decodedPreviousParameterValuePart = previousParameterValueParts[counter] as String
                                // TO_DO:burayı kontrol et java'da "\\|" yapmak gerekiyordu.
                                let decodedPreviousParameterValuePartArray = decodedPreviousParameterValuePart
                                    .components(separatedBy: "|")
                                if decodedPreviousParameterValuePartArray.count == 2 {
                                    parameterValueToStore += ("~")
                                    parameterValueToStore += (decodedPreviousParameterValuePart)
                                }
                            }
                        }
                        targetParameters[storeKey] = parameterValueToStore
                    }
                }
            }

            saveUserDefaults(RelatedDigitalConstants.userDefaultsTargetKey, withObject: targetParameters)
        }
    }

    class func readTargetParameters() -> [String: String] {
        guard let targetParameters = readUserDefaults(RelatedDigitalConstants.userDefaultsTargetKey)
                as? [String: String] else {
            return [String: String]()
        }
        return targetParameters
    }

    class func clearTargetParameters() {
        removeUserDefaults(RelatedDigitalConstants.userDefaultsTargetKey)
    }

    // MARK: - USER DEFAULTS

    static func saveUserDefaults(_ key: String, withObject value: Any?) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func readUserDefaults(_ key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    static func removeUserDefaults(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func clearUserDefaults() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: RelatedDigitalConstants.cookieIdKey)
        ud.removeObject(forKey: RelatedDigitalConstants.exvisitorIdKey)
        ud.synchronize()
    }
    
    static func saveBlock(_ block: Bool) {
        saveUserDefaults(RelatedDigitalConstants.userDefaultsBlockKey, withObject: block)
    }
    
    static func isBlocked() -> Bool {
        return readUserDefaults(RelatedDigitalConstants.userDefaultsBlockKey) as? Bool ?? false
    }

    static func saveRelatedDigitalProfile(_ relatedDigitalProfile: RelatedDigitalProfile) {
        let encoder = JSONEncoder()
        if let encodedRelatedDigitalProfile = try? encoder.encode(relatedDigitalProfile) {
            saveUserDefaults(RelatedDigitalConstants.userDefaultsProfileKey, withObject: encodedRelatedDigitalProfile)
        }
    }

    static func readRelatedDigitalProfile() -> RelatedDigitalProfile? {
        if let savedRelatedDigitalProfile = readUserDefaults(RelatedDigitalConstants.userDefaultsProfileKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedRelatedDigitalProfile = try? decoder.decode(RelatedDigitalProfile.self, from: savedRelatedDigitalProfile) {
                return loadedRelatedDigitalProfile
            }
        }
        return nil
    }

    static func saveRelatedDigitalGeofenceHistory(_ relatedDigitalGeofenceHistory: RelatedDigitalGeofenceHistory) {
        let encoder = JSONEncoder()
        if let encodedRelatedDigitalGeofenceHistory = try? encoder.encode(relatedDigitalGeofenceHistory) {
            saveUserDefaults(RelatedDigitalConstants.userDefaultsGeofenceHistoryKey,
                             withObject: encodedRelatedDigitalGeofenceHistory)
        }
    }

    public static func readRelatedDigitalGeofenceHistory() -> RelatedDigitalGeofenceHistory {
        if let savedRelatedDigitalGeofenceHistory =
            readUserDefaults(RelatedDigitalConstants.userDefaultsGeofenceHistoryKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedRelatedDigitalGeofenceHistory = try? decoder.decode(RelatedDigitalGeofenceHistory.self,
                                                                       from: savedRelatedDigitalGeofenceHistory) {
                return loadedRelatedDigitalGeofenceHistory
            }
        }
        return RelatedDigitalGeofenceHistory()
    }

    public static func clearRelatedDigitalGeofenceHistory() {
        removeUserDefaults(RelatedDigitalConstants.userDefaultsGeofenceHistoryKey)
    }

}
