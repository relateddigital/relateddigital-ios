//
//  TargetingDelegates.swift
//  RelatedDigitalExample
//
//  Single owner for every targeting-action callback the SDK offers. Registering
//  once at launch means links and button taps are captured no matter which
//  screen the user is on when the action appears.
//

import Foundation
import RelatedDigitalIOS

final class TargetingDelegateHub: NSObject {

    static let shared = TargetingDelegateHub()

    private var isRegistered = false

    private override init() { super.init() }

    func register() {
        guard !isRegistered else { return }
        isRegistered = true
        RelatedDigital.inappButtonDelegate = self
        RelatedDigital.countdownUrlDelegate = self
        RelatedDigital.notificationBellUrlDelegate = self
        Task { @MainActor in
            RDLog.info("Targeting delegates registered", channel: .targeting,
                       detail: "inappButtonDelegate\ncountdownUrlDelegate\nnotificationBellUrlDelegate")
        }
    }
}

// MARK: - In-app buttons

extension TargetingDelegateHub: RDInappButtonDelegate {

    func didTapButton(_ notification: RDInAppNotification) {
        let link = notification.iosLink ?? "—"
        Task { @MainActor in
            RDLog.result("In-app button tapped", channel: .targeting, detail: "iosLink = \(link)")
        }
    }

    func didTapSecondButton(_ notification: RDInAppNotification) {
        let link = notification.iosLink ?? "—"
        Task { @MainActor in
            RDLog.result("In-app secondary button tapped", channel: .targeting, detail: "iosLink = \(link)")
        }
    }

    func didTapCarouselFullscreenButton(_ notification: RDInAppNotification,
                                        link: String?,
                                        button: RDCarouselFullscreenButton,
                                        carouselItemIndex: Int) {
        Task { @MainActor in
            RDLog.result("Fullscreen carousel button tapped", channel: .targeting,
                         detail: "index = \(carouselItemIndex)\nlink = \(link ?? "—")")
        }
    }
}

// MARK: - Story, countdown and notification-bell links
//
// Both protocols declare the same `urlClicked(_:)` selector, so one
// implementation satisfies them together.

extension TargetingDelegateHub: RDStoryURLDelegate, RDNotificationBellDelegate {

    func urlClicked(_ url: URL) {
        Task { @MainActor in
            RDLog.result("Targeting link tapped", channel: .targeting, detail: url.absoluteString)
        }
    }
}
