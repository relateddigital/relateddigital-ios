//
//  RelatedDigitalInstance.swift
//  
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation



public class RelatedDigitalInstance : CustomDebugStringConvertible {
    
    var relatedDigitalUser: RelatedDigitalUser!
    var relatedDigitalProfile: RelatedDigitalProfile!
    var relatedDigitalCookie = RelatedDigitalLoadBalancerCookie()
    var relatedDigitalAnalytics: RelatedDigitalAnalytics
    var relatedDigitalPushNotifications: RelatedDigitalPushNotification
    let readWriteLock: RelatedDigitalReadWriteLock
    var trackingQueue: DispatchQueue!
    var eventsQueue = Queue()
    let RelatedDigitalEventInstance: RelatedDigitalInstance
    var networkQueue: DispatchQueue!
    let RelatedDigitalSendInstance: RelatedDigitalSend


    public var debugDescription: String {
        return "Visilabs(siteId : // TODO:" +
            "organizationId: // TODO:"
    }
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
        relatedDigitalProfile = RelatedDigitalProfile(organizationId: organizationId, profileId: profileId, dataSource: dataSource)
        relatedDigitalAnalytics = RelatedDigitalAnalytics(relatedDigitalProfile: relatedDigitalProfile)
        relatedDigitalPushNotifications = RelatedDigitalPushNotification(relatedDigitalProfile: relatedDigitalProfile)
        readWriteLock = RelatedDigitalReadWriteLock(label: "RelatedDigitalInstanceLock")
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
    
    public static func sharedUIApplication() -> UIApplication? {
        let shared = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue()
        guard let sharedApplication = shared as? UIApplication else {
            return nil
        }
        return sharedApplication
    }
    
    public func customEvent(_ pageName: String, properties: [String: String]) {
        
//        if VisilabsPersistence.isBlocked() {
//            VisilabsLogger.warn("Too much server load, ignoring the request!")
//            return
//        }
//
//        if pageName.isEmptyOrWhitespace {
//            VisilabsLogger.error("customEvent can not be called with empty page name.")
//            return
//        }
//
//        checkPushPermission()
        
        trackingQueue.async { [weak self, pageName, properties] in
            guard let self = self else { return }
            var eQueue = Queue()
            var vUser = relatedDigitalUser()
            var chan = ""
            self.readWriteLock.read {
                eQueue = self.eventsQueue
                vUser = self.relatedDigitalUser
                chan = self.relatedDigitalProfile.channel
            }
            let result = self.RelatedDigitalEventInstance.customEvent(pageName: pageName,
                                                                properties: properties,
                                                                eventsQueue: eQueue,
                                                                visilabsUser: vUser,
                                                                channel: chan)
            self.readWriteLock.write {
                self.eventsQueue = result.eventsQueque
                self.relatedDigitalUser = result.visilabsUser
                self.relatedDigitalProfile.channel = result.channel
            }
            self.readWriteLock.read {
                RelatedDigitalPersistence.archiveUser(self.relatedDigitalUser)
                if result.clearUserParameters {
                    RelatedDigitalPersistence.clearTargetParameters()
                }
            }
            if let event = self.eventsQueue.last {
                RelatedDigitalPersistence.saveTargetParameters(event)
                if RelatedDigitalBasePath.endpoints[.action] != nil,
                   self.relatedDigitalProfile.inAppNotificationsEnabled,
                   pageName != RelatedDigitalConstants.omEvtGif {
                    self.checkInAppNotification(properties: event)
                    self.checkTargetingActions(properties: event)
                }
            }
            self.send()
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



extension RelatedDigitalInstance {
    private func send() {
        trackingQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var eQueue = Queue()
                var vUser = RelatedDigitalUser()
                var vCookie = RelatedDigitalLoadBalancerCookie()
                self.readWriteLock.read {
                    eQueue = self.eventsQueue
                    vUser = self.relatedDigitalUser
                    vCookie = self.relatedDigitalCookie
                }
                self.readWriteLock.write {
                    self.eventsQueue.removeAll()
                }
                let cookie = self.RelatedDigitalSendInstance.sendEventsQueue(eQueue,
                                                                       visilabsUser: vUser,
                                                                       visilabsCookie: vCookie,
                                                                       timeoutInterval: self.relatedDigitalProfile.requestTimeoutInterval)
                self.readWriteLock.write {
                    self.relatedDigitalCookie = cookie
                }
            }
        }
    }
}
