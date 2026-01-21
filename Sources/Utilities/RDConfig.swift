//
//  RDConfig.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import Foundation

public class RDConfig {
    public var organizationId: String
    public var profileId: String
    public var dataSource: String
    public var appAlias: String
    
    // Optional settings
    public var logEnabled: Bool = true
    public var askLocationPermissionAtStart: Bool = true
    public var enablePushNotifications: Bool = true
    public var autoIntegrate: Bool = true
    public var twitterId: String?
    public var facebookId: String?
    
    public init(organizationId: String, profileId: String, dataSource: String, appAlias: String) {
        self.organizationId = organizationId
        self.profileId = profileId
        self.dataSource = dataSource
        self.appAlias = appAlias
    }
    
    /// Initializes RDConfig from RelatedDigital-Info.plist
    public convenience init?(fileName: String = "RelatedDigital-Info") {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        
        guard let orgId = dict["OrganizationId"] as? String,
              let profId = dict["ProfileId"] as? String,
              let source = dict["DataSource"] as? String,
              let alias = dict["AppAlias"] as? String else {
            return nil
        }
        
        self.init(organizationId: orgId, profileId: profId, dataSource: source, appAlias: alias)
        
        // Load optionals if they exist
        if let log = dict["LogEnabled"] as? Bool {
            self.logEnabled = log
        }
        
        if let loc = dict["AskLocationPermissionAtStart"] as? Bool {
            self.askLocationPermissionAtStart = loc
        }
        
        if let push = dict["EnablePushNotifications"] as? Bool {
            self.enablePushNotifications = push
        }
        
        if let twitterId = dict["TwitterId"] as? String {
            self.twitterId = twitterId
        }
        
        if let facebookId = dict["FacebookId"] as? String {
            self.facebookId = facebookId
        }
        
        if let auto = dict["AutoIntegrate"] as? Bool {
            self.autoIntegrate = auto
        }
    }
}
