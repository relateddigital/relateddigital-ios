//
//  RDAutoIntegrator.swift
//  RelatedDigitalIOS
//
//  Created by Related Digital on 14.01.2026.
//

import Foundation
import UIKit
import UserNotifications

class RDAutoIntegrator: NSObject {
    
    static func integrate() {
        guard let delegate = UIApplication.shared.delegate else {
            return
        }
        
        let delegateClass: AnyClass = type(of: delegate)
        
        swizzleDidRegister(delegateClass: delegateClass)
        swizzleDidReceive(delegateClass: delegateClass)
        swizzleUNUserNotificationCenter()
    }
    
    private static func swizzleDidRegister(delegateClass: AnyClass) {
        let originalSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let swizzledSelector = #selector(rd_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        swizzleMethod(cls: delegateClass, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private static func swizzleDidReceive(delegateClass: AnyClass) {
        let originalSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let swizzledSelector = #selector(rd_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        swizzleMethod(cls: delegateClass, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private static func swizzleUNUserNotificationCenter() {
        // Swizzle setDelegate:
        let cls = UNUserNotificationCenter.self
        let originalSelector = #selector(setter: UNUserNotificationCenter.delegate)
        let swizzledSelector = #selector(UNUserNotificationCenter.rd_setDelegate(_:))
        
        guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UNUserNotificationCenter.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        // If delegate is already set, wrap it now.
        if let currentDelegate = UNUserNotificationCenter.current().delegate, !(currentDelegate is RDUNUserNotificationCenterDelegate) {
            UNUserNotificationCenter.current().delegate = currentDelegate // This calls our swizzled setDelegate because we swapped it!
        } else if UNUserNotificationCenter.current().delegate == nil {
            // Set our delegate if none
             UNUserNotificationCenter.current().delegate = RDUNUserNotificationCenterDelegate(originalDelegate: nil)
        }
    }
    
    private static func swizzleMethod(cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let swizzledMethod = class_getInstanceMethod(RDAutoIntegrator.self, swizzledSelector) else { return }
        
        let didAddMethod = class_addMethod(cls,
                                           originalSelector,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            // Method didn't exist, we added it.
        } else {
            // Method exists, swipe it.
            
            // 1. Add our method to the class under the swizzled selector
            class_addMethod(cls,
                            swizzledSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod))
            
            // 2. Exchange
            guard let originalMethod = class_getInstanceMethod(cls, originalSelector),
                  let swizzledMethodOnCls = class_getInstanceMethod(cls, swizzledSelector) else { return }
            
            method_exchangeImplementations(originalMethod, swizzledMethodOnCls)
        }
    }
    
    // MARK: - Swizzled Implementations
    
    @objc func rd_application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Call RelatedDigital
        RelatedDigital.registerToken(tokenData: deviceToken)
        
        // Call Original (if exists)
        let selector = #selector(RDAutoIntegrator.rd_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        if self.responds(to: selector) {
            self.perform(selector, with: application, with: deviceToken)
        }
    }
    
    @objc func rd_application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Call RelatedDigital
        RelatedDigital.handlePush(pushDictionary: userInfo)
        
        // Call Original (if exists)
        let selector = #selector(RDAutoIntegrator.rd_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        if self.responds(to: selector) {
            typealias FunctionType = @convention(c) (AnyObject, Selector, UIApplication, [AnyHashable: Any], @escaping (UIBackgroundFetchResult) -> Void) -> Void
            
            if let method = class_getInstanceMethod(type(of: self), selector) {
                let imp = method_getImplementation(method)
                let function = unsafeBitCast(imp, to: FunctionType.self)
                function(self, selector, application, userInfo, completionHandler)
            }
        } else {
            completionHandler(.newData)
        }
    }
}

// MARK: - UNUserNotificationCenter Swizzling & Proxy

extension UNUserNotificationCenter {
    @objc func rd_setDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
        // 'self' here is the UNUserNotificationCenter instance.
        // We want to wrap the delegate.
        
        if let delegate = delegate, !(delegate is RDUNUserNotificationCenterDelegate) {
            let proxy = RDUNUserNotificationCenterDelegate(originalDelegate: delegate)
            // Call original setDelegate (which is now at rd_setDelegate selector name)
            self.rd_setDelegate(proxy)
        } else {
            // If delegate is nil, we might still want to set our proxy?
            // If user unsets delegate, maybe we should respect that or keep ours?
            // Let's keep ours if they set nil? No, usually that means "stop handling".
            // But for SDK auto-integration, we probably always want ours.
            // If nil passed, use Proxy with nil original.
            if delegate == nil {
                 let proxy = RDUNUserNotificationCenterDelegate(originalDelegate: nil)
                 self.rd_setDelegate(proxy)
            } else {
                 self.rd_setDelegate(delegate)
            }
        }
    }
}

class RDUNUserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var originalDelegate: UNUserNotificationCenterDelegate?
    
    init(originalDelegate: UNUserNotificationCenterDelegate?) {
        self.originalDelegate = originalDelegate
        super.init()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Always show alert/badge/sound by default for foreground
        // But maybe configurable?
        // SDK logic:
        // completionHandler([.alert, .badge, .sound])
        
        // If original delegate exists, ask it.
        if let original = originalDelegate, original.responds(to: #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))) {
            original.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        } else {
            // Default behavior if no delegate: Show everything
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle RelatedDigital logic
        RelatedDigital.handlePush(pushDictionary: response.notification.request.content.userInfo)
        RelatedDigital.handlePushWithActionButtons(response: response, type: self) // Type issue? handlePushWithActionButtons expects 'Any'. In AppDelegate it passed 'self'.
        
        // Forward to original
        if let original = originalDelegate, original.responds(to: #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            original.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        return originalDelegate?.responds(to: aSelector) ?? false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return originalDelegate
    }
}

extension RDUNUserNotificationCenterDelegate: PushAction {
    func actionButtonClicked(identifier: String, url: String) {
        // Forward action click if needed?
        // Basic handling: open URL
        if let urlObj = URL(string: url) {
            UIApplication.shared.open(urlObj)
        }
    }
}
