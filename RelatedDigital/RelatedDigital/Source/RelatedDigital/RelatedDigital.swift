//
//  RelatedDigital.swift
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

import Foundation
import UIKit

/**
 * RelatedDigital manages the shared state for all RelatedDigital services. RelatedDigital.create should be
 * called from within your application delegate's `application:didFinishLaunchingWithOptions:` method
 * to initialize the shared instance.
 */


/// Main entry point for RelatedDigital. The application must call `create` during `application:didFinishLaunchingWithOptions:`
/// before accesing any instances on RelatedDigital or RelatedDigital modules. // TODO: RelatedDigital modules demeye gerek var mı?
@objc
public class RelatedDigital: NSObject {
    
    
    
    /// A flag that checks if the RelatedDigital instance is available. `true` if available, otherwise `false`.
    @objc
    public static var isCreated : Bool {
        get {
            return RelatedDigital._shared != nil
        }
    }
    
    static var _shared: RelatedDigital?
    
    
    
    /// Shared RelatedDigital instance.
    @objc
    public static var shared: RelatedDigital {
        if (!RelatedDigital.isCreated) {
            assertionFailure("Create must be called before accessing RelatedDigital.")
        }
        return _shared!
    }
    
    
    /// Initalizes RelatedDigital. The values of `organizationId`,`profileId`,`dataSource` could be obtained by
    /// [RelatedDigital Admin Panel](https://intelligence.relateddigital.com/#Management/UserManagement/Profiles) and selecting relevant profile.
    ///
    /// - Warning: Call this method from the main thread in your `AppDelegate` class before calling any other RelatedDigital methods.
    ///
    /// - Parameters:
    ///     - organizationId: The ID of your organization.
    ///     - profileId: The ID of the profile you want to integrate.
    ///     - dataSource: The data source of the profile you want to integrate.
    ///     - launchOptions: The launch options passed into `application:didFinishLaunchingWithOptions:`
    ///
    @objc
    public class func create(organizationId: String, profileId: String, dataSource: String, launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        
        guard Thread.isMainThread else {
            fatalError("create must be called on the main thread.")
        }
        
        
    }
    
    
}
