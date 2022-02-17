//
//  RDPersistence.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 23.12.2021.
//

import Foundation

public class RDPersistence {
    
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
    
    class func archiveUser(_ rdUser: RelatedDigitalUser) {
        archiveQueueUtility.sync { [rdUser] in
            let propertiesFilePath = filePath(filename: RDConstants.userArchiveKey)
            guard let path = propertiesFilePath else {
                RDLogger.error("bad file path, cant fetch file")
                return
            }
            var userDic = [String: String?]()
            userDic[RDConstants.cookieIdKey] = rdUser.cookieId
            userDic[RDConstants.exvisitorIdKey] = rdUser.exVisitorId
            userDic[RDConstants.appidKey] = rdUser.appId
            userDic[RDConstants.tokenIdKey] = rdUser.tokenId
            userDic[RDConstants.userAgentKey] = rdUser.userAgent
            userDic[RDConstants.visitorCappingKey] = rdUser.visitorData
            userDic[RDConstants.visitorData] = rdUser.visitorData
            userDic[RDConstants.mobileIdKey] = rdUser.identifierForAdvertising
            userDic[RDConstants.mobileSdkVersion] = rdUser.sdkVersion
            userDic[RDConstants.mobileAppVersion] = rdUser.appVersion
            
            userDic[RDConstants.lastEventTimeKey] = rdUser.lastEventTime
            userDic[RDConstants.nrvKey] = String(rdUser.nrv)
            userDic[RDConstants.pvivKey] = String(rdUser.pviv)
            userDic[RDConstants.tvcKey] = String(rdUser.tvc)
            userDic[RDConstants.lvtKey] = rdUser.lvt
            
            if !NSKeyedArchiver.archiveRootObject(userDic, toFile: path) {
                RDLogger.error("failed to archive user")
            }
        }
    }
    
    // TO_DO: bunu ExceptionWrapper içine al
    // swiftlint:disable cyclomatic_complexity
    class func unarchiveUser() -> RelatedDigitalUser {
        var relatedDigitalUser = RelatedDigitalUser()
        // Before Visilabs.identity is used as archive key, to retrieve Visilabs.cookieID set by objective-c library
        // we added this control.
        if let cidfp = filePath(filename: RDConstants.identityArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            relatedDigitalUser.cookieId = cid
        }
        if let cidfp = filePath(filename: RDConstants.cookieidArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            relatedDigitalUser.cookieId = cid
        }
        if let exvidfp = filePath(filename: RDConstants.exvisitorIdArchiveKey),
           let exvid = NSKeyedUnarchiver.unarchiveObject(withFile: exvidfp) as? String {
            relatedDigitalUser.exVisitorId = exvid
        }
        if let appidfp = filePath(filename: RDConstants.appidArchiveKey),
           let aid = NSKeyedUnarchiver.unarchiveObject(withFile: appidfp) as? String {
            relatedDigitalUser.appId = aid
        }
        if let tidfp = filePath(filename: RDConstants.tokenidArchiveKey),
           let tid = NSKeyedUnarchiver.unarchiveObject(withFile: tidfp) as? String {
            relatedDigitalUser.tokenId = tid
        }
        if let uafp = filePath(filename: RDConstants.useragentArchiveKey),
           let userAgent = NSKeyedUnarchiver.unarchiveObject(withFile: uafp) as? String {
            relatedDigitalUser.userAgent = userAgent
        }
        
        if let propsfp = filePath(filename: RDConstants.userArchiveKey),
           let props = NSKeyedUnarchiver.unarchiveObject(withFile: propsfp) as? [String: String?] {
            if let cid = props[RDConstants.cookieIdKey], !cid.isNilOrWhiteSpace {
                relatedDigitalUser.cookieId = cid
            }
            if let exvid = props[RDConstants.exvisitorIdKey], !exvid.isNilOrWhiteSpace {
                relatedDigitalUser.exVisitorId = exvid
            }
            if let aid = props[RDConstants.appidKey], !aid.isNilOrWhiteSpace {
                relatedDigitalUser.appId = aid
            }
            if let tid = props[RDConstants.tokenIdKey], !tid.isNilOrWhiteSpace {
                relatedDigitalUser.tokenId = tid
            }
            if let userAgent = props[RDConstants.userAgentKey], !userAgent.isNilOrWhiteSpace {
                relatedDigitalUser.userAgent = userAgent
            }
            if let visitorData = props[RDConstants.visitorData], !visitorData.isNilOrWhiteSpace {
                relatedDigitalUser.visitorData = visitorData
            }
            // TO_DO: visilabsUserda ya üstteki kod gereksiz ya da alttaki yanlış
            if let visitorData = props[RDConstants.visitorCappingKey], !visitorData.isNilOrWhiteSpace {
                relatedDigitalUser.visitorData = visitorData
            }
            if let madid = props[RDConstants.mobileIdKey], !madid.isNilOrWhiteSpace {
                relatedDigitalUser.identifierForAdvertising = madid
            }
            if let sdkversion = props[RDConstants.mobileSdkVersion], !sdkversion.isNilOrWhiteSpace {
                relatedDigitalUser.sdkVersion = sdkversion
            }
            if let appversion = props[RDConstants.mobileAppVersion], !appversion.isNilOrWhiteSpace {
                relatedDigitalUser.appVersion = appversion
            }
            if let lastEventTime = props[RDConstants.lastEventTimeKey] as? String {
                relatedDigitalUser.lastEventTime = lastEventTime
            }
            if let nrvString = props[RDConstants.nrvKey] as? String, let nrv = Int(nrvString)  {
                relatedDigitalUser.nrv = nrv
            }
            if let pvivString = props[RDConstants.pvivKey] as? String, let pviv = Int(pvivString)  {
                relatedDigitalUser.pviv = pviv
            }
            if let tvcString = props[RDConstants.tvcKey] as? String, let tvc = Int(tvcString)  {
                relatedDigitalUser.tvc = tvc
            }
            if let lvt = props[RDConstants.lvtKey] as? String {
                relatedDigitalUser.lvt = lvt
            }
        } else {
            RDLogger.warn("Related Digital: Error while unarchiving properties.")
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
            
            for rdParameter in RDConstants.rdTargetParameters() {
                let key = rdParameter.key
                let storeKey = rdParameter.storeKey
                let relatedKeys = rdParameter.relatedKeys
                let count = rdParameter.count
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
            
            saveUserDefaults(RDConstants.userDefaultsTargetKey, withObject: targetParameters)
        }
    }
    
    class func readTargetParameters() -> [String: String] {
        guard let targetParameters = readUserDefaults(RDConstants.userDefaultsTargetKey)
                as? [String: String] else {
                    return [String: String]()
                }
        return targetParameters
    }
    
    class func clearTargetParameters() {
        removeUserDefaults(RDConstants.userDefaultsTargetKey)
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
        ud.removeObject(forKey: RDConstants.cookieIdKey)
        ud.removeObject(forKey: RDConstants.exvisitorIdKey)
        ud.synchronize()
    }
    
    static func saveBlock(_ block: Bool) {
        saveUserDefaults(RDConstants.userDefaultsBlockKey, withObject: block)
    }
    
    static func isBlocked() -> Bool {
        return readUserDefaults(RDConstants.userDefaultsBlockKey) as? Bool ?? false
    }
    
    static func saveRelatedDigitalProfile(_ rdProfile: RelatedDigitalProfile) {
        if let encodedRDProfile = try? JSONEncoder().encode(rdProfile) {
            saveUserDefaults(RDConstants.userDefaultsProfileKey, withObject: encodedRDProfile)
        }
    }
    
    static func readRDProfile() -> RelatedDigitalProfile? {
        if let savedRDProfile = readUserDefaults(RDConstants.userDefaultsProfileKey) as? Data {
            if let loadedRDProfile = try? JSONDecoder().decode(RelatedDigitalProfile.self, from: savedRDProfile) {
                return loadedRDProfile
            }
        }
        return nil
    }
    
    static func saveRDGeofenceHistory(_ rdGeofenceHistory: RelatedDigitalGeofenceHistory) {
        if let encodedRdGeofenceHistory = try? JSONEncoder().encode(rdGeofenceHistory) {
            saveUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey, withObject: encodedRdGeofenceHistory)
        }
    }
    
    public static func readRDGeofenceHistory() -> RelatedDigitalGeofenceHistory {
        if let savedRDGeofenceHistory = readUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey) as? Data {
            if let loadedRDGeofenceHistory = try? JSONDecoder().decode(RelatedDigitalGeofenceHistory.self, from: savedRDGeofenceHistory) {
                return loadedRDGeofenceHistory
            }
        }
        return RelatedDigitalGeofenceHistory()
    }
    
    public static func clearRDGeofenceHistory() {
        removeUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey)
    }
    
}
