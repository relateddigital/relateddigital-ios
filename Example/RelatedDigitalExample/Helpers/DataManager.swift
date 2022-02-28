//
//  DataManager.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation

class DataManager {

    static let relatedDigitalProfileKey = "RelatedDigitalProfile"

    static func saveRelatedDigitalProfile(_ relatedDigitalProfile: RelatedDigitalProfile) {
        let encoder = JSONEncoder()
        if let encodedRelatedDigitalProfile = try? encoder.encode(relatedDigitalProfile) {
            save(relatedDigitalProfileKey, withObject: encodedRelatedDigitalProfile)
        }
    }

    static func readRelatedDigitalProfile() -> RelatedDigitalProfile? {
        if let savedRelatedDigitalProfile = read(relatedDigitalProfileKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedRelatedDigitalProfile = try? decoder.decode(RelatedDigitalProfile.self, from: savedRelatedDigitalProfile) {
                return loadedRelatedDigitalProfile
            }
        }
        return nil
    }

    static func save(_ key: String, withObject value: Any?) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func read(_ key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    static func remove(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }

}
