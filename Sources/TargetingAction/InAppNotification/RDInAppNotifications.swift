//
//  RDInAppNotifications.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.11.2021.
//

import Foundation
import UIKit

protocol RDInAppNotificationsDelegate: AnyObject {
    func notificationDidShow(_ notification: RDInAppNotification)
    func trackNotification(_ notification: RDInAppNotification, event: String, properties: Properties)
}

class RDInAppNotifications: RDNotificationViewControllerDelegate {
    let lock: RDReadWriteLock
    var miniNotificationPresentationTime = 6.0
    var currentlyShowingNotification: RDInAppNotification?
    var currentlyShowingTargetingAction: TargetingActionViewModel?
    weak var delegate: RDInAppNotificationsDelegate?
    weak var inappButtonDelegate: RDInappButtonDelegate?
    weak var currentViewController: UIViewController?

    init(lock: RDReadWriteLock) {
        self.lock = lock
    }

    func showNotification(_ notification: RDInAppNotification) {
        let notification = notification
        let delayTime = notification.waitingTime ?? 0
        DispatchQueue.main.async {
            self.currentViewController = RDHelper.getRootViewController()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(delayTime), execute: {
            if self.currentlyShowingNotification != nil || self.currentlyShowingTargetingAction != nil {
                RDLogger.warn("already showing an in-app notification")
            } else {
                if notification.waitingTime ?? 0 == 0 || self.currentViewController == RDHelper.getRootViewController() {
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
                    case .alert:
                        shownNotification = true
                        self.showAlert(notification)
                    default:
                        shownNotification = self.showPopUp(notification)
                    }

                    if shownNotification {
                        self.markNotificationShown(notification: notification)
                        self.delegate?.notificationDidShow(notification)
                    }
                }
            }
        })
    }

    func showTargetingAction(_ model: TargetingActionViewModel) {
        DispatchQueue.main.async {
            if self.currentlyShowingNotification != nil || self.currentlyShowingTargetingAction != nil {
                RDLogger.warn("already showing an notification")
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
        let giftCatchVC = GiftCatchViewController(giftCatchViewModel)
        giftCatchVC.delegate = self
        giftCatchVC.show(animated: true)
        return true
    }

    func showFindToWin(findToWinModel: FindToWinViewModel) -> Bool {
        let findToWinVC = FindToWinViewController(findToWinModel)
        findToWinVC.delegate = self
        findToWinVC.show(animated: true)
        return true
    }
    
    func showGiftBox(giftBoxModel: GiftBoxModel) -> Bool {
        let giftBoxVC = GiftBoxViewController(giftBoxModel)
        giftBoxVC.delegate = self
        giftBoxVC.show(animated: true)
        return true
    }
    
    func showChooseFavorite(model: ChooseFavoriteModel) -> Bool {
        let chooseFavoriteVC = ChooseFavoriteGameViewController(model)
        chooseFavoriteVC.delegate = self
        chooseFavoriteVC.show(animated: true)
        return true
    }

    func showDrawer(model: DrawerServiceModel) -> Bool {
        let drawerViewController = RDDrawerViewController(model: model)
        drawerViewController.delegate = self
        drawerViewController.show(animated: true)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + miniNotificationPresentationTime) {
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
        let popUpVC = RDPopupNotificationViewController(scratchToWin: model)
        popUpVC.delegate = self
        popUpVC.inappButtonDelegate = inappButtonDelegate
        popUpVC.show(animated: false)
        return true
    }

    func showSpinToWin(_ model: SpinToWinViewModel) -> Bool {
        let spinToWinVC = RDSpinToWinViewController(model)
        spinToWinVC.delegate = self
        spinToWinVC.show(animated: true)
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
            currentlyShowingNotification = notification
            // TO_DO: burada customEvent request'i atılmalı
        }
    }

    func markTargetingActionShown(model: TargetingActionViewModel) {
        lock.write {
            self.currentlyShowingTargetingAction = model
        }
    }

    @discardableResult
    func notificationShouldDismiss(controller: RDBaseViewControllerProtocol, callToActionURL: URL?, shouldTrack: Bool, additionalTrackingProperties: Properties?) -> Bool {
        if currentlyShowingNotification?.actId != controller.notification?.actId {
            return false
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
            self.currentlyShowingNotification = nil
            self.currentlyShowingTargetingAction = nil
        }

        if let callToActionURL = callToActionURL {
            controller.hide(animated: true) {
                if callToActionURL.absoluteString == "redirect" {
                    if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
                        completionBlock()
                    }
                } else {
                    let app = RDInstance.sharedUIApplication()
                    app?.performSelector(onMainThread: NSSelectorFromString("openURL:"), with: callToActionURL, waitUntilDone: true)
                    completionBlock()
                }
            }
        } else {
            controller.hide(animated: true, completion: completionBlock)
        }

        return true
    }

    func alertDismiss() {
        currentlyShowingNotification = nil
        currentlyShowingTargetingAction = nil
    }
}
