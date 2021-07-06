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

