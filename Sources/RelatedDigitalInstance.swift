//
//  RelatedDigitalInstance.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

public class RelatedDigitalInstance {

    var relatedDigitalUser: RelatedDigitalUser!
    var relatedDigitalProfile: RelatedDigitalProfile!
    var relatedDigitalCookie = RelatedDigitalCookie()


    //TODO: bunun satır sayısını azaltabilirsin
    public var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                RelatedDigitalLogger.enableLevel(.debug)
                RelatedDigitalLogger.enableLevel(.info)
                RelatedDigitalLogger.enableLevel(.warning)
                RelatedDigitalLogger.enableLevel(.error)
                RelatedDigitalLogger.info("Logging Enabled")
            } else {
                RelatedDigitalLogger.info("Logging Disabled")
                RelatedDigitalLogger.disableLevel(.debug)
                RelatedDigitalLogger.disableLevel(.info)
                RelatedDigitalLogger.disableLevel(.warning)
                RelatedDigitalLogger.disableLevel(.error)
            }
        }
    }

    public var useInsecureProtocol: Bool = false
    
    /*{
        didSet {
            self.relatedDigitalProfile.useInsecureProtocol = useInsecureProtocol
            setEndpoints(dataSource: self.relatedDigitalProfile.dataSource,
                                        useInsecureProtocol: useInsecureProtocol)
            saveRelatedDigitalProfile(self.relatedDigitalProfile)
        }
    }
 */
    

    init(organizationId: String, profileId: String, dataSource: String) {
        self.relatedDigitalProfile = RelatedDigitalProfile(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
    }
    
    public func enablePushNotifications(appAlias: String) {
        self.relatedDigitalProfile.pushNotificationsEnabled = true
        self.relatedDigitalProfile.appAlias = appAlias
    }
    
    public func disablePushNotifications() {
        self.relatedDigitalProfile.pushNotificationsEnabled = false
    }
    
    
    
    public func tryLog(logType: Int, message: String){
        if logType == 1 {
            RelatedDigitalLogger.debug(message)
        } else if  logType == 2 {
            RelatedDigitalLogger.info(message)
        } else if  logType == 3 {
            RelatedDigitalLogger.warn(message)
        } else {
            RelatedDigitalLogger.error(message)
        }
    }
    
    /*
    convenience init?() {
        let canReadFromUserDefaults = false
        if canReadFromUserDefaults {
            self.init(organizationId: "", profileId: "", dataSource: "")
        } else {
            return nil
        }
    }
 */

}

