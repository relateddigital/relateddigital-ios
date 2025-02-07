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

    class func archiveUser(_ rdUser: RDUser) {
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
            userDic[RDConstants.mobileSdkType] = rdUser.sdkType
            userDic[RDConstants.mobileAppVersion] = rdUser.appVersion
            userDic[RDConstants.utmCampaignKey] = rdUser.utmCampaign
            userDic[RDConstants.utmMediumKey] = rdUser.utmMedium
            userDic[RDConstants.utmSourceKey] = rdUser.utmSource
            userDic[RDConstants.utmContentKey] = rdUser.utmContent
            userDic[RDConstants.utmTermKey] = rdUser.utmTerm
            userDic[RDConstants.isPushUser] = rdUser.isPushUser
            userDic[RDConstants.pushTime] = rdUser.pushTime

            userDic[RDConstants.lastEventTimeKey] = rdUser.lastEventTime
            userDic[RDConstants.nrvKey] = String(rdUser.nrv)
            userDic[RDConstants.pvivKey] = String(rdUser.pviv)
            userDic[RDConstants.tvcKey] = String(rdUser.tvc)
            userDic[RDConstants.lvtKey] = rdUser.lvt

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: userDic, requiringSecureCoding: false)
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
                print("Kullanıcı arşivlendi")
            } catch {
                RDLogger.error("failed to archive user: \(error.localizedDescription)")
            }
        }
    }
    
    class func unarchiveString(from filename: String) -> String? {
        if let filePath = RDPersistence.filePath(filename: filename),
           let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) as? String
            
        }
        return nil
    }
    

    // TO_DO: bunu ExceptionWrapper içine al
    // swiftlint:disable cyclomatic_complexity
    class func unarchiveUser() -> RDUser {
        
        var relatedDigitalUser = RDUser()
        // Before Visilabs.identity is used as archive key, to retrieve Visilabs.cookieID set by objective-c library
        // we added this control.
        
        
        if let cid = unarchiveString(from: RDConstants.identityArchiveKey) {
            relatedDigitalUser.cookieId = cid
        }
        if let cid = unarchiveString(from: RDConstants.cookieidArchiveKey) {
            relatedDigitalUser.cookieId = cid
        }
        if let exvid = unarchiveString(from: RDConstants.exvisitorIdArchiveKey) {
            relatedDigitalUser.exVisitorId = exvid
        }
        if let aid = unarchiveString(from: RDConstants.appidArchiveKey) {
            relatedDigitalUser.appId = aid
        }
        if let tid = unarchiveString(from: RDConstants.tokenidArchiveKey) {
            relatedDigitalUser.tokenId = tid
        }
        if let userAgent = unarchiveString(from: RDConstants.useragentArchiveKey) {
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
            if let sdktype = props[RDConstants.mobileSdkType], !sdktype!.isEmptyOrWhitespace {
                relatedDigitalUser.sdkType = sdktype
            }
            if let appversion = props[RDConstants.mobileAppVersion], !appversion.isNilOrWhiteSpace {
                relatedDigitalUser.appVersion = appversion
            }
            if let campaign = props[RDConstants.utmCampaignKey], !campaign.isNilOrWhiteSpace {
                relatedDigitalUser.utmCampaign = campaign
            }
            if let medium = props[RDConstants.utmMediumKey], !medium.isNilOrWhiteSpace {
                relatedDigitalUser.utmMedium = medium
            }
            if let source = props[RDConstants.utmSourceKey], !source.isNilOrWhiteSpace {
                relatedDigitalUser.utmSource = source
            }
            if let content = props[RDConstants.utmContentKey], !content.isNilOrWhiteSpace {
                relatedDigitalUser.utmContent = content
            }
            if let term = props[RDConstants.utmTermKey], !term.isNilOrWhiteSpace {
                relatedDigitalUser.utmTerm = term
            }
            if let lastEventTime = props[RDConstants.lastEventTimeKey] as? String {
                relatedDigitalUser.lastEventTime = lastEventTime
            }
            if let nrvString = props[RDConstants.nrvKey] as? String, let nrv = Int(nrvString) {
                relatedDigitalUser.nrv = nrv
            }
            if let pvivString = props[RDConstants.pvivKey] as? String, let pviv = Int(pvivString) {
                relatedDigitalUser.pviv = pviv
            }
            if let tvcString = props[RDConstants.tvcKey] as? String, let tvc = Int(tvcString) {
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
    class func saveTargetParameters(_ parameters: Properties) {
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
                                let relatedKeyValue = parameters[relatedKey]?
                                    .trimmingCharacters(in: CharacterSet.whitespaces)
                                parameterValueToStore += "|"
                                parameterValueToStore += (relatedKeyValue ?? "")
                            } else { parameterValueToStore += "|0" }
                            parameterValueToStore += "|" + dateString
                            targetParameters[storeKey] = parameterValueToStore
                        } else {
                            targetParameters[storeKey] = parameterValue
                        }
                    } else if count > 1 {
                        let previousParameterValue = targetParameters[storeKey]
                        let parameterValueToStore = (parameterValue.copy() as? String ?? "")
                        var parameterValueToStoreWithDate = parameterValueToStore + "|" + dateString
                        if previousParameterValue != nil && previousParameterValue!.count > 0 {
                            let previousParameterValueParts = previousParameterValue!.components(separatedBy: "~")
                            var paramCounter = 1
                            for counter in 0 ..< previousParameterValueParts.count {
                                if paramCounter == 10 {
                                    break
                                }
                                let decodedPreviousParameterValuePart = previousParameterValueParts[counter] as String
                                // TO_DO:burayı kontrol et java'da "\\|" yapmak gerekiyordu.
                                let decodedPreviousParameterValuePartArray = decodedPreviousParameterValuePart
                                    .components(separatedBy: "|")
                                if decodedPreviousParameterValuePartArray.count == 2 {
                                    if decodedPreviousParameterValuePartArray[0] == parameterValueToStore {
                                        continue
                                    }
                                    parameterValueToStoreWithDate += "~"
                                    parameterValueToStoreWithDate += decodedPreviousParameterValuePart
                                    paramCounter = paramCounter + 1
                                }
                            }
                        }
                        targetParameters[storeKey] = parameterValueToStoreWithDate
                    }
                }
            }

            saveUserDefaults(RDConstants.userDefaultsTargetKey, withObject: targetParameters)
        }
    }

    class func readTargetParameters() -> Properties {
        guard let targetParameters = readUserDefaults(RDConstants.userDefaultsTargetKey) as? Properties else {
            return Properties()
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
        ud.removeObject(forKey: RDConstants.utmCampaignKey)
        ud.removeObject(forKey: RDConstants.utmSourceKey)
        ud.removeObject(forKey: RDConstants.utmMediumKey)
        ud.removeObject(forKey: RDConstants.utmContentKey)
        ud.removeObject(forKey: RDConstants.utmTermKey)
        ud.synchronize()
    }

    static func saveBlock(_ block: Bool) {
        saveUserDefaults(RDConstants.userDefaultsBlockKey, withObject: block)
    }

    static func isBlocked() -> Bool {
        return readUserDefaults(RDConstants.userDefaultsBlockKey) as? Bool ?? false
    }

    static func saveRDProfile(_ rdProfile: RDProfile) {
        if let encodedRDProfile = try? JSONEncoder().encode(rdProfile) {
            saveUserDefaults(RDConstants.userDefaultsProfileKey, withObject: encodedRDProfile)
        }
    }

    static func readRDProfile() -> RDProfile? {
        if let savedRDProfile = readUserDefaults(RDConstants.userDefaultsProfileKey) as? Data {
            if let loadedRDProfile = try? JSONDecoder().decode(RDProfile.self, from: savedRDProfile) {
                return loadedRDProfile
            }
        }
        return nil
    }

    static func saveRDGeofenceHistory(_ rdGeofenceHistory: RDGeofenceHistory) {
        if let encodedRdGeofenceHistory = try? JSONEncoder().encode(rdGeofenceHistory) {
            saveUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey, withObject: encodedRdGeofenceHistory)
        }
    }

    public static func readRDGeofenceHistory() -> RDGeofenceHistory {
        if let savedRDGeofenceHistory = readUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey) as? Data {
            if let loadedRDGeofenceHistory = try? JSONDecoder().decode(RDGeofenceHistory.self, from: savedRDGeofenceHistory) {
                return loadedRDGeofenceHistory
            }
        }
        return RDGeofenceHistory()
    }

    public static func clearRDGeofenceHistory() {
        removeUserDefaults(RDConstants.userDefaultsGeofenceHistoryKey)
    }
}
