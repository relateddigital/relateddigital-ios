//
//  RDInAppNotifications.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.11.2021.
//

import Foundation
import UIKit
import StoreKit

protocol RDInAppNotificationsDelegate: AnyObject {
    func notificationDidShow(_ notification: RDInAppNotification)
    func trackNotification(_ notification: RDInAppNotification, event: String, properties: Properties)
}

private class ScheduledNotificationItem {
    let notification: RDInAppNotification
    var workItem: DispatchWorkItem?
    let scheduledDate: Date
    let delayTime: TimeInterval

    init(notification: RDInAppNotification, workItem: DispatchWorkItem? = nil, scheduledDate: Date = Date(), delayTime: TimeInterval) {
        self.notification = notification
        self.workItem = workItem
        self.scheduledDate = scheduledDate
        self.delayTime = delayTime
    }
}

class RDInAppNotifications: RDNotificationViewControllerDelegate {
    let lock: RDReadWriteLock
    var miniNotificationPresentationTime = 6.0
    var currentlyShowingNotification: RDInAppNotification?
    var currentlyShowingTargetingAction: TargetingActionViewModel?
    weak var delegate: RDInAppNotificationsDelegate?
    weak var inappButtonDelegate: RDInappButtonDelegate?
    weak var countdownUrlDelegate: RDStoryURLDelegate?
    weak var notificationBellUrlDelegate: RDNotificationBellDelegate?
    weak var drawerUrlDelegate: RDDrawerURLDelegate?
    weak var currentViewController: UIViewController?
    weak var currentlyShowingBell: NotificationBellViewController?

    private var pendingNotifications: [RDInAppNotification] = []
    private var scheduledNotificationIds: Set<Int> = []
    private var scheduledNotifications: [Int: ScheduledNotificationItem] = [:]
    private var recentlyShownNotificationIds: [Int: Date] = [:]
    private let deduplicationTimeInterval: TimeInterval = 30.0
    private let maxNotificationRetries = 10
    private var lastDismissedTime: Date?
    private let chainedDismissThreshold: TimeInterval = 5.0
    private let fastTrackTransitionDelay: TimeInterval = 0.3

    init(lock: RDReadWriteLock) {
        self.lock = lock
    }

    func showNotification(_ notification: RDInAppNotification) {
        let actId = notification.actId

        var isAlreadyShowing = false
        var isAlreadyPending = false
        var isAlreadyScheduled = false
        var isRecentlyShown = false

        lock.write {
            let now = Date()
            self.recentlyShownNotificationIds = self.recentlyShownNotificationIds.filter { now.timeIntervalSince($0.value) < self.deduplicationTimeInterval }

            if self.currentlyShowingNotification?.actId == actId || self.currentlyShowingTargetingAction?.actIdValue == actId {
                isAlreadyShowing = true
            }
            if self.pendingNotifications.contains(where: { $0.actId == actId }) {
                isAlreadyPending = true
            }
            if self.scheduledNotificationIds.contains(actId) {
                isAlreadyScheduled = true
            }
            if self.recentlyShownNotificationIds[actId] != nil {
                isRecentlyShown = true
            }

            if !isAlreadyShowing && !isAlreadyPending && !isAlreadyScheduled && !isRecentlyShown {
                self.scheduledNotificationIds.insert(actId)
            }
        }

        if isAlreadyShowing {
            RDLogger.info("Notification \(actId) is already currently showing. Dropping duplicate.")
            return
        }
        if isAlreadyPending {
            RDLogger.info("Notification \(actId) is already in pending queue. Dropping duplicate.")
            return
        }
        if isAlreadyScheduled {
            RDLogger.info("Notification \(actId) is already scheduled to show. Dropping duplicate.")
            return
        }
        if isRecentlyShown {
            RDLogger.info("Notification \(actId) was shown recently (< \(deduplicationTimeInterval)s ago). Dropping duplicate.")
            return
        }

        let delayTime = notification.waitingTime ?? 0

        // Check if this notification arrived as part of a chained flow right after a previous dismissal
        var shouldFastTrack = false
        lock.read {
            if let lastDismiss = self.lastDismissedTime, Date().timeIntervalSince(lastDismiss) < self.chainedDismissThreshold {
                shouldFastTrack = true
            }
        }

        if shouldFastTrack {
            RDLogger.info("Notification \(actId) arrived shortly after previous dismiss (< \(chainedDismissThreshold)s). Fast-tracking display (in \(fastTrackTransitionDelay)s) instead of waiting \(delayTime)s.")
            lock.write {
                self.lastDismissedTime = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + fastTrackTransitionDelay) { [weak self] in
                self?.lock.write {
                    self?.scheduledNotificationIds.remove(actId)
                    self?.scheduledNotifications.removeValue(forKey: actId)
                }
                self?.attemptToShowNotification(notification, retryCount: 0)
            }
            return
        }

        RDLogger.info("showNotification scheduled with waitingTime: \(delayTime)s for actId: \(actId)")

        if delayTime > 0 {
            let scheduledItem = ScheduledNotificationItem(notification: notification, delayTime: TimeInterval(delayTime))

            let workItem = DispatchWorkItem { [weak self] in
                self?.lock.write {
                    self?.scheduledNotifications.removeValue(forKey: actId)
                    self?.scheduledNotificationIds.remove(actId)
                }
                self?.attemptToShowNotification(notification, retryCount: 0)
            }
            scheduledItem.workItem = workItem

            lock.write {
                self.scheduledNotifications[actId] = scheduledItem
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(delayTime), execute: workItem)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.lock.write {
                    self?.scheduledNotificationIds.remove(actId)
                    self?.scheduledNotifications.removeValue(forKey: actId)
                }
                self?.attemptToShowNotification(notification, retryCount: 0)
            }
        }
    }

    private func attemptToShowNotification(_ notification: RDInAppNotification, retryCount: Int = 0) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication(),
              sharedUIApplication.applicationState != .background else {
            RDLogger.warn("Application is in background, adding notification \(notification.actId) to pending queue.")
            queuePendingNotification(notification)
            return
        }

        var isBusy = false
        var isAlreadyShowingThis = false
        lock.read {
            if self.currentlyShowingNotification?.actId == notification.actId || self.currentlyShowingTargetingAction?.actIdValue == notification.actId {
                isAlreadyShowingThis = true
            }
            isBusy = (self.currentlyShowingNotification != nil || self.currentlyShowingTargetingAction != nil)
        }

        if isAlreadyShowingThis {
            RDLogger.info("Notification \(notification.actId) is already on screen. Dropping duplicate.")
            lock.write {
                self.scheduledNotificationIds.remove(notification.actId)
                self.scheduledNotifications.removeValue(forKey: notification.actId)
            }
            return
        }

        if isBusy {
            if retryCount < maxNotificationRetries {
                RDLogger.info("Another in-app or action is currently showing. Retrying in 0.5s... (attempt \(retryCount + 1)/\(maxNotificationRetries))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.attemptToShowNotification(notification, retryCount: retryCount + 1)
                }
            } else {
                RDLogger.info("Max retries reached while waiting. Adding notification \(notification.actId) to pending queue.")
                queuePendingNotification(notification)
            }
            return
        }

        guard let rootViewController = RDHelper.getRootViewController() else {
            RDLogger.warn("No active visible view controller found to present notification \(notification.actId). Retrying in 0.5s...")
            if retryCount < maxNotificationRetries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.attemptToShowNotification(notification, retryCount: retryCount + 1)
                }
            }
            return
        }

        if rootViewController.isBeingDismissed {
            RDLogger.info("Current view controller is being dismissed, waiting 0.3s before presenting notification \(notification.actId).")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.attemptToShowNotification(notification, retryCount: retryCount + 1)
            }
            return
        }

        presentNotification(notification)
    }

    private func presentNotification(_ notification: RDInAppNotification) {
        var shownNotification = false
        switch notification.type {
        case .mini:
            shownNotification = self.showMiniNotification(notification)
        case .full:
            shownNotification = self.showFullNotification(notification)
        case .halfScreenImage:
            shownNotification = self.showHalfScreenNotification(notification)
        case .inappcarousel:
            shownNotification = self.showCarousel(notification)
        case .carouselFullscreen:
            shownNotification = self.showCarouselFullscreen(notification)
        case .fullscreenPopup:
            shownNotification = self.showFullscreenPopup(notification)
        case .alert:
            shownNotification = true
            self.showAlert(notification)
        default:
            shownNotification = self.showPopUp(notification)
        }

        if shownNotification {
            self.markNotificationShown(notification: notification)
            self.delegate?.notificationDidShow(notification)
            self.lock.write {
                self.recentlyShownNotificationIds[notification.actId] = Date()
            }
        } else {
            RDLogger.error("Failed to present notification \(notification.actId).")
        }
    }

    private func queuePendingNotification(_ notification: RDInAppNotification) {
        lock.write {
            if self.currentlyShowingNotification?.actId == notification.actId {
                RDLogger.info("Notification \(notification.actId) is already currently showing. Not queuing duplicate.")
                return
            }
            if !self.pendingNotifications.contains(where: { $0.actId == notification.actId }) {
                self.pendingNotifications.append(notification)
                RDLogger.info("Notification \(notification.actId) added to pending queue (size: \(self.pendingNotifications.count)).")
            }
        }
    }

    private func getEffectiveDelay(for delaySeconds: Int) -> Double {
        var shouldFastTrack = false
        lock.read {
            if let lastDismiss = self.lastDismissedTime, Date().timeIntervalSince(lastDismiss) < self.chainedDismissThreshold {
                shouldFastTrack = true
            }
        }
        if shouldFastTrack {
            lock.write {
                self.lastDismissedTime = nil
            }
            RDLogger.info("Action arrived shortly after previous dismiss (< \(chainedDismissThreshold)s). Fast-tracking (\(fastTrackTransitionDelay)s) instead of waiting \(delaySeconds)s.")
            return fastTrackTransitionDelay
        }
        return Double(delaySeconds)
    }

    private func showNextPendingNotificationIfAny() {
        var scheduledToFastTrack: RDInAppNotification?

        lock.write {
            let now = Date()
            self.pendingNotifications.removeAll { notif in
                if let lastShown = self.recentlyShownNotificationIds[notif.actId], now.timeIntervalSince(lastShown) < self.deduplicationTimeInterval {
                    RDLogger.info("Removing recently shown notification \(notif.actId) from pending queue.")
                    return true
                }
                return false
            }

            // If there is any notification waiting on a waitingTime timer, fast-track the earliest scheduled one
            // because the previous popup/action has been dismissed.
            if let firstScheduled = self.scheduledNotifications.values.sorted(by: { $0.scheduledDate < $1.scheduledDate }).first {
                firstScheduled.workItem?.cancel()
                self.scheduledNotifications.removeValue(forKey: firstScheduled.notification.actId)
                self.scheduledNotificationIds.remove(firstScheduled.notification.actId)
                scheduledToFastTrack = firstScheduled.notification
            }
        }

        if let fastTrackNotif = scheduledToFastTrack {
            var isRecentlyShown = false
            lock.read {
                if let lastShown = self.recentlyShownNotificationIds[fastTrackNotif.actId],
                   Date().timeIntervalSince(lastShown) < self.deduplicationTimeInterval {
                    isRecentlyShown = true
                }
            }
            if isRecentlyShown {
                RDLogger.info("Fast-tracked notification \(fastTrackNotif.actId) was shown recently. Dropping duplicate.")
                showNextPendingNotificationIfAny()
                return
            }

            RDLogger.info("Previous popup dismissed. Fast-tracking scheduled notification \(fastTrackNotif.actId) in \(fastTrackTransitionDelay)s.")
            DispatchQueue.main.asyncAfter(deadline: .now() + fastTrackTransitionDelay) { [weak self] in
                self?.attemptToShowNotification(fastTrackNotif, retryCount: 0)
            }
            return
        }

        var nextNotif: RDInAppNotification?
        lock.write {
            if !self.pendingNotifications.isEmpty {
                nextNotif = self.pendingNotifications.removeFirst()
            }
        }
        if let next = nextNotif {
            RDLogger.info("Triggering next pending notification: \(next.actId)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.attemptToShowNotification(next, retryCount: 0)
            }
        }
    }

    func showTargetingAction(_ model: TargetingActionViewModel) {
        if let actId = model.actIdValue {
            var isAlreadyShowing = false
            var isAlreadyPending = false
            var isAlreadyScheduled = false
            var isRecentlyShown = false

            lock.write {
                let now = Date()
                self.recentlyShownNotificationIds = self.recentlyShownNotificationIds.filter { now.timeIntervalSince($0.value) < self.deduplicationTimeInterval }

                if self.currentlyShowingNotification?.actId == actId || self.currentlyShowingTargetingAction?.actIdValue == actId {
                    isAlreadyShowing = true
                }
                if self.pendingNotifications.contains(where: { $0.actId == actId }) {
                    isAlreadyPending = true
                }
                if self.scheduledNotificationIds.contains(actId) {
                    isAlreadyScheduled = true
                }
                if self.recentlyShownNotificationIds[actId] != nil {
                    isRecentlyShown = true
                }

                if !isAlreadyShowing && !isAlreadyPending && !isAlreadyScheduled && !isRecentlyShown {
                    self.scheduledNotificationIds.insert(actId)
                }
            }

            if isAlreadyShowing {
                RDLogger.info("Targeting action \(actId) is already currently showing. Dropping duplicate.")
                return
            }
            if isAlreadyPending {
                RDLogger.info("Targeting action \(actId) is already in pending queue. Dropping duplicate.")
                return
            }
            if isAlreadyScheduled {
                RDLogger.info("Targeting action \(actId) is already scheduled to show. Dropping duplicate.")
                return
            }
            if isRecentlyShown {
                RDLogger.info("Targeting action \(actId) was shown recently (< \(deduplicationTimeInterval)s ago). Dropping duplicate.")
                return
            }
        }

        DispatchQueue.main.async {
            if self.currentlyShowingNotification != nil || self.currentlyShowingTargetingAction != nil {
                RDLogger.warn("already showing an notification")
                if let actId = model.actIdValue {
                    self.lock.write {
                        self.scheduledNotificationIds.remove(actId)
                        self.scheduledNotifications.removeValue(forKey: actId)
                    }
                }
            } else {
                if model.targetingActionType == .mailSubscriptionForm, let mailSubscriptionForm = model as? MailSubscriptionViewModel {
                    if self.showMailPopup(mailSubscriptionForm) {
                        self.markTargetingActionShown(model: mailSubscriptionForm)
                    }
                } else if model.targetingActionType == .spinToWin, let spinToWin = model as? SpinToWinViewModel {
                    if self.showSpinToWin(spinToWin) {
                        self.markTargetingActionShown(model: spinToWin)
                    }
                } else if model.targetingActionType == .scratchToWin, let sctw = model as? ScratchToWinModel {
                    if self.showScratchToWin(sctw) {
                        self.markTargetingActionShown(model: sctw)
                    }
                } else if model.targetingActionType == .productStatNotifier, let psn = model as? RDProductStatNotifierViewModel {
                    if self.showProductStatNotifier(psn) {
                        self.markTargetingActionShown(model: psn)
                    }
                } else if model.targetingActionType == .drawer, let drawer = model as? DrawerServiceModel {
                    if self.showDrawer(model: drawer) {
                        //self.markTargetingActionShown(model: drawer)
                    }
                } else if model.targetingActionType == .notificationBell, let notifBell = model as? NotificationBellModel {
                    if self.showNotificationBell(model: notifBell) {
                        //self.markTargetingActionShown(model: drawer)
                    }
                }  else if model.targetingActionType == .CountdownTimerBanner, let timerBanner = model as? RDCountdownTimerBannerModel {
                    if self.showTimerBanner(model: timerBanner) {
                        self.markTargetingActionShown(model: timerBanner)
                    }
                } else if model.targetingActionType == .downHsView, let downHsView = model as? downHsViewServiceModel {
                    if self.showDownhs(model: downHsView) {
                        self.markTargetingActionShown(model: downHsView)
                    }
                } else if model.targetingActionType == .giftCatch, let giftCatchViewModel = model as? GiftCatchViewModel {
                    if self.showGiftCatch(giftCatchViewModel: giftCatchViewModel) {
                        self.markTargetingActionShown(model: giftCatchViewModel)
                    }
                } else if model.targetingActionType == .findToWin, let findToWin = model as? FindToWinViewModel {
                    if self.showFindToWin(findToWinModel: findToWin) {
                        self.markTargetingActionShown(model: findToWin)
                    }
                } else if model.targetingActionType == .giftBox, let giftBox = model as? GiftBoxModel {
                    if self.showGiftBox(giftBoxModel: giftBox) {
                        self.markTargetingActionShown(model: giftBox)
                    }
                } else if model.targetingActionType == .shakeToWin, let shakeToWin = model as? ShakeToWinViewModel {
                    if self.showShakeToWin(model: shakeToWin) {
                        self.markTargetingActionShown(model: shakeToWin)
                    }
                } else if model.targetingActionType == .chooseFavorite, let chooseFavorite = model as? ChooseFavoriteModel {
                    if self.showChooseFavorite(model: chooseFavorite) {
                        self.markTargetingActionShown(model: chooseFavorite)
                    }
                } else if model.targetingActionType == .mobileCustomActions, let customWebview = model as? CustomWebViewModel {
                    if self.showCustomWebview(model: customWebview) {
                        self.markTargetingActionShown(model: customWebview)
                    }
                } else if model.targetingActionType == .slotMachine, let jackpot = model as? JackpotModel {
                   if self.showJackpot(model: jackpot) {
                       self.markTargetingActionShown(model: jackpot)
                   }
               }  else if model.targetingActionType == .MultipleChoiceSurvey, let survey = model as? PollModel {
                   if self.showPoll(model: survey) {
                       self.markTargetingActionShown(model: survey)
                   }
               }else if model.targetingActionType == .clawMachine, let clawMachine = model as? ClawMachineModel {
                   if self.showClawMachine(model: clawMachine) {
                       self.markTargetingActionShown(model: clawMachine)
                   }
               }
                else if model.targetingActionType == .apprating {
                    self.showInappRating()
               }
            }
        }
    }

    func showShakeToWin(model: ShakeToWinViewModel) -> Bool {
        let shakeToWinViewController = ShakeToWinViewController(model: model)
        shakeToWinViewController.delegate = self
        shakeToWinViewController.show(animated: true)
        return true
    }

    func showGiftCatch(giftCatchViewModel: GiftCatchViewModel) -> Bool {
        let delay = getEffectiveDelay(for: giftCatchViewModel.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let giftCatchVC = GiftCatchViewController(giftCatchViewModel)
            giftCatchVC.delegate = self
            giftCatchVC.show(animated: true)
        })

        return true
    }

    func showFindToWin(findToWinModel: FindToWinViewModel) -> Bool {
        let delay = getEffectiveDelay(for: findToWinModel.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let findToWinVC = FindToWinViewController(findToWinModel)
            findToWinVC.delegate = self
            findToWinVC.show(animated: true)
        })

        return true
    }
    
    func showGiftBox(giftBoxModel: GiftBoxModel) -> Bool {
        let delay = getEffectiveDelay(for: giftBoxModel.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let giftBoxVC = GiftBoxViewController(giftBoxModel)
            giftBoxVC.delegate = self
            giftBoxVC.show(animated: true)
        })

        return true
    }
    
    func showChooseFavorite(model: ChooseFavoriteModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let chooseFavoriteVC = ChooseFavoriteGameViewController(model)
            chooseFavoriteVC.delegate = self
            chooseFavoriteVC.show(animated: true)
        })
        return true
    }
    
    func showCustomWebview(model: CustomWebViewModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let customWebviewVC = CustomWebViewController(model)
            customWebviewVC.delegate = self
            customWebviewVC.show(animated: true)
        })
        return true
    }
    
    func showInappRating() {
        DispatchQueue.main.async  {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    func showJackpot(model: JackpotModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let jackpotVC = JackpotViewController(model)
            jackpotVC.delegate = self
            jackpotVC.show(animated: true)
        })

        return true
    }
    
    func showTimerBanner(model: RDCountdownTimerBannerModel) -> Bool {
        // Geri sayım süresi dolmuşsa banner hiç gösterilmez.
        if CountdownTimerBannerViewController.isExpired(model: model) {
            RDLogger.info("CountdownTimerBanner expired, not showing.")
            return false
        }
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            // Bekleme süresi içinde süre dolmuş olabilir; tekrar kontrol et.
            if CountdownTimerBannerViewController.isExpired(model: model) {
                RDLogger.info("CountdownTimerBanner expired, not showing.")
                return
            }
            let tBannerVC = CountdownTimerBannerViewController(model: model)
            tBannerVC.delegate = self
            tBannerVC.urlDelegate = self.countdownUrlDelegate
            tBannerVC.show(animated: true)

        })
        return true
    }
    
    func showPoll(model: PollModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let pollVC = PollViewController(model)
            pollVC.delegate = self
            pollVC.show(animated: true)
        })

        return true
    }
    
    func showClawMachine(model: ClawMachineModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let clawMachineVC = ClawMachineViewController(model)
            clawMachineVC.delegate = self
            clawMachineVC.show(animated: true)
        })
        return true
    }

    func showDrawer(model: DrawerServiceModel) -> Bool {
        let drawerViewController = RDDrawerViewController(model: model)
        drawerViewController.delegate = self
        drawerViewController.urlDelegate = self.drawerUrlDelegate
        drawerViewController.show(animated: true)
        return true
    }

    func showNotificationBell(model: NotificationBellModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            // Prevent stacking multiple bell windows on top of each other.
            // A new targeting action request can arrive on every page/visit; without
            // this guard each one created a new bell window at the same position,
            // and dragging the top one revealed the duplicates underneath.
            if let existingBell = self.currentlyShowingBell {
                existingBell.closeAction()
                self.currentlyShowingBell = nil
            }

            let notifBell = NotificationBellViewController(model: model)
            notifBell.delegate = self
            notifBell.urlDelegate = self.notificationBellUrlDelegate
            notifBell.show(animated: true)
            self.currentlyShowingBell = notifBell

        })
        return true
    }
    
    public func showDownhs(model: downHsViewServiceModel) -> Bool {
        let downhsViewController = downHsViewController(model: model)
        downhsViewController.delegate = self
        downhsViewController.show(animated: true)
        return true
    }

    func showProductStatNotifier(_ model: RDProductStatNotifierViewModel) -> Bool {
        let productStatNotifierVC = RDProductStatNotifierViewController(productStatNotifier: model)
        productStatNotifierVC.delegate = self
        productStatNotifierVC.show(animated: true)
        return true
    }

    func showHalfScreenNotification(_ notification: RDInAppNotification) -> Bool {
        let halfScreenNotificationVC = RDHalfScreenViewController(notification: notification)
        halfScreenNotificationVC.delegate = self
        halfScreenNotificationVC.show(animated: true)
        return true
    }

    func showMiniNotification(_ notification: RDInAppNotification) -> Bool {
        let miniNotificationVC = RelatedDigitalMiniNotificationViewController(notification: notification)
        miniNotificationVC.delegate = self
        miniNotificationVC.show(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(notification.duration ?? 6)) {
            self.notificationShouldDismiss(controller: miniNotificationVC, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
        }
        return true
    }

    func showFullNotification(_ notification: RDInAppNotification) -> Bool {
        let fullNotificationVC = RelatedDigitalFullNotificationViewController(notification: notification)
        fullNotificationVC.delegate = self
        fullNotificationVC.show(animated: true)
        return true
    }

    func showCarousel(_ notification: RDInAppNotification) -> Bool {
        if notification.carouselItems.count < 2 {
            RDLogger.error("Carousel Item Count is less than 2.")
            return false
        }
        let vc = RDCarouselNotificationViewController(startIndex: 0, notification: notification)
        vc.rdDelegate = self
        vc.launchedCompletion = { RDLogger.info("Carousel Launched") }
        vc.closedCompletion = {
            RDLogger.info("Carousel Closed")
            vc.rdDelegate?.notificationShouldDismiss(controller: vc, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
        }
        vc.landedPageAtIndexCompletion = { index in
            RDLogger.info("LANDED AT INDEX: \(index)")
        }
        if let rootViewController = RDHelper.getRootViewController() {
            rootViewController.presentCarouselNotification(vc)
            return true
        } else {
            return false
        }
    }

    func showCarouselFullscreen(_ notification: RDInAppNotification) -> Bool {
        let items = Array(notification.carouselItems.prefix(5))
        if items.isEmpty {
            RDLogger.error("Carousel fullscreen items are empty.")
            return false
        }
        let vc = RDCarouselFullscreenViewController(notification: notification, carouselItems: items)
        vc.delegate = self
        vc.onButtonTap = { [weak self] notif, link, button, index in
            self?.inappButtonDelegate?.didTapCarouselFullscreenButton(notif, link: link, button: button, carouselItemIndex: index)
        }
        vc.show(animated: true)
        return true
    }

    func showFullscreenPopup(_ notification: RDInAppNotification) -> Bool {
        let vc = RDFullscreenPopupViewController(notification: notification)
        vc.delegate = self
        vc.inappButtonDelegate = inappButtonDelegate
        vc.show(animated: true)
        return true
    }

    func showAlert(_ notification: RDInAppNotification) {
        let title = notification.messageTitle?.removeEscapingCharacters()
        let message = notification.messageBody?.removeEscapingCharacters()
        let style: UIAlertController.Style = notification.alertType?.lowercased() ?? "" == "actionsheet" ? .actionSheet : .alert
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

        let buttonTxt = notification.buttonText
        let urlStr = notification.iosLink ?? ""
        let action = UIAlertAction(title: buttonTxt, style: .default) { _ in
            guard let url = URL(string: urlStr) else {
                return
            }
            RDInstance.sharedUIApplication()?.open(url, options: [:], completionHandler: nil)
            self.inappButtonDelegate?.didTapButton(notification)
        }

        let closeText = notification.closeButtonText ?? "Close"
        let close = UIAlertAction(title: closeText, style: .destructive) { _ in
            print("dismiss tapped")
        }

        alertController.addAction(action)
        alertController.addAction(close)

        if let root = RDHelper.getRootViewController() {
            if UIDevice.current.userInterfaceIdiom == .pad, style == .actionSheet {
                alertController.popoverPresentationController?.sourceView = root.view
                alertController.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.maxY, width: 0, height: 0)
            }

            root.present(alertController, animated: true, completion: alertDismiss)
        }
    }

    func showScratchToWin(_ model: ScratchToWinModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute:{
            let popUpVC = RDPopupNotificationViewController(scratchToWin: model)
            popUpVC.delegate = self
            popUpVC.inappButtonDelegate = self.inappButtonDelegate
            popUpVC.show(animated: false)

        })
        return true
    }

    func showSpinToWin(_ model: SpinToWinViewModel) -> Bool {
        let delay = getEffectiveDelay(for: model.waitingTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            let spinToWinVC = RDSpinToWinViewController(model)
            spinToWinVC.delegate = self
            spinToWinVC.show(animated: true)
        })
        return true
    }

    func showPopUp(_ notification: RDInAppNotification) -> Bool {
        let popUpVC = RDPopupNotificationViewController(notification: notification)
        popUpVC.delegate = self
        popUpVC.inappButtonDelegate = inappButtonDelegate
        popUpVC.show(animated: false)
        return true
    }

    func showMailPopup(_ model: MailSubscriptionViewModel) -> Bool {
        let popUpVC = RDPopupNotificationViewController(mailForm: model)
        popUpVC.delegate = self
        popUpVC.show(animated: false)
        return true
    }

    func markNotificationShown(notification: RDInAppNotification) {
        lock.write {
            RDLogger.info("marking notification as seen: \(notification.actId)")
            self.currentlyShowingNotification = notification
            self.scheduledNotificationIds.remove(notification.actId)
            self.scheduledNotifications.removeValue(forKey: notification.actId)
            // TO_DO: burada customEvent request'i atılmalı
        }
    }

    func markTargetingActionShown(model: TargetingActionViewModel) {
        lock.write {
            self.currentlyShowingTargetingAction = model
            if let actId = model.actIdValue {
                self.scheduledNotificationIds.remove(actId)
                self.scheduledNotifications.removeValue(forKey: actId)
                self.recentlyShownNotificationIds[actId] = Date()
                RDLogger.info("marking targeting action as seen: \(actId)")
            }
        }
    }

    @discardableResult
    func notificationShouldDismiss(controller: RDBaseViewControllerProtocol, callToActionURL: URL?, shouldTrack: Bool, additionalTrackingProperties: Properties?) -> Bool {
        if let currentNotif = currentlyShowingNotification, let controllerNotif = controller.notification {
            if currentNotif.actId != controllerNotif.actId {
                return false
            }
        }

        let completionBlock = {
            if shouldTrack {
                var properties = additionalTrackingProperties ?? Properties()
                if additionalTrackingProperties != nil {
                    properties["OM.s_point"] = additionalTrackingProperties!["OM.s_point"]
                    properties["OM.s_cat"] = additionalTrackingProperties!["OM.s_cat"]
                    properties["OM.s_page"] = additionalTrackingProperties!["OM.s_page"]
                }
                if controller.notification != nil {
                    self.delegate?.trackNotification(controller.notification!, event: "event", properties: properties)
                }
            }
            self.lock.write {
                self.currentlyShowingNotification = nil
                self.currentlyShowingTargetingAction = nil
                self.lastDismissedTime = Date()
            }
            self.showNextPendingNotificationIfAny()
        }

        if let callToActionURL = callToActionURL {
            controller.hide(animated: true) {
                if callToActionURL.absoluteString == "redirect" {
                    if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
                        completionBlock()
                    }
                } else {
                    UIApplication.shared.open(callToActionURL as URL, options: [:], completionHandler: nil)
                    completionBlock()
                }
            }
        } else {
            controller.hide(animated: true, completion: completionBlock)
        }

        return true
    }

    func alertDismiss() {
        lock.write {
            currentlyShowingNotification = nil
            currentlyShowingTargetingAction = nil
            lastDismissedTime = Date()
        }
        showNextPendingNotificationIfAny()
    }

    func trackNotification(controller: RDBaseViewControllerProtocol, event: String, properties: Properties?) {
        if let notification = controller.notification {
            var finalProperties = properties ?? Properties()
            if let addProps = properties {
                if let point = addProps["OM.s_point"] { finalProperties["OM.s_point"] = point }
                if let cat = addProps["OM.s_cat"] { finalProperties["OM.s_cat"] = cat }
                if let page = addProps["OM.s_page"] { finalProperties["OM.s_page"] = page }
                if let feed = addProps["OM.s_feed"] { finalProperties["OM.s_feed"] = feed }
            }
            self.delegate?.trackNotification(notification, event: event, properties: finalProperties)
        }
    }
}

extension TargetingActionViewModel {
    var actIdValue: Int? {
        if let m = self as? SpinToWinViewModel { return m.actId }
        if let m = self as? ScratchToWinModel { return m.actId }
        if let m = self as? MailSubscriptionViewModel { return m.actId }
        if let m = self as? PollModel { return m.actId }
        if let m = self as? RDCountdownTimerBannerModel { return m.actId }
        if let m = self as? DrawerServiceModel { return m.actId }
        if let m = self as? CustomWebViewModel { return m.actId }
        if let m = self as? NotificationBellModel { return m.actId }
        if let m = self as? InappReviewModel { return m.actId }
        if let m = self as? GiftCatchViewModel { return m.actId }
        if let m = self as? FindToWinViewModel { return m.actId }
        if let m = self as? GiftBoxModel { return m.actId }
        if let m = self as? ShakeToWinViewModel { return m.actId }
        if let m = self as? ChooseFavoriteModel { return m.actId }
        if let m = self as? JackpotModel { return m.actId }
        if let m = self as? ClawMachineModel { return m.actId }
        if let m = self as? downHsViewServiceModel { return m.actId }
        return nil
    }
}
