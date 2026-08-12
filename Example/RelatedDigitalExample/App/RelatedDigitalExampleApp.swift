//
//  RelatedDigitalExampleApp.swift
//  RelatedDigitalExample
//
//  Sample application for the Related Digital iOS SDK.
//

import SwiftUI

@main
struct RelatedDigitalExampleApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var config = AppConfig.shared
    @StateObject private var log = EventLog.shared
    @StateObject private var push = PushCenter.shared
    @StateObject private var toast = ToastCenter()

    var body: some Scene {
        WindowGroup {
            // `toastOverlay` reads ToastCenter from the environment, so the
            // environment objects have to be injected above it.
            RootView()
                .toastOverlay()
                .tint(Theme.accent)
                .environmentObject(config)
                .environmentObject(log)
                .environmentObject(push)
                .environmentObject(toast)
        }
    }
}
