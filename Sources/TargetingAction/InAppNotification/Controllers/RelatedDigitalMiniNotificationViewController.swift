//
//  RelatedDigitalMiniNotificationViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 13.05.2020.
//

import UIKit

class RelatedDigitalMiniNotificationViewController: RDBaseNotificationViewController {

    var miniNotification: RDInAppNotification! {
        return super.notification
    }

    @IBOutlet weak var closeButton: UILabel!
    @IBOutlet weak var circleLabel: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    var isDismissing = false
    var canPan = true
    var position: CGPoint!
    var isTop = false

    convenience init(notification: RDInAppNotification) {
        self.init(notification: notification,
                  nameOfClass: String(describing: RelatedDigitalMiniNotificationViewController.self))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if notification?.pos != "bottom" {
            isTop = true
        }
        
        if notification?.closeButtonColor?.toHexString() != nil {
            closeButton.textColor = notification?.closeButtonColor
        } else {
            closeButton.isHidden = true
        }
        
        titleLabel.text = notification!.messageTitle?.replacingOccurrences(of: "\\n", with: "\n")
        titleLabel.textColor = notification?.messageTitleColor
        titleLabel.font = notification!.messageTitleFont
        titleLabel.tintColor = notification?.messageTitleColor
        if let url = notification!.imageUrl {
            let stringUrl = url.absoluteString
            let replaceString = stringUrl.replacingOccurrences(of: "@2x", with: "")
            
            imageView.setImage(withUrl: URL(string: replaceString))
        }
        
        view.backgroundColor = notification?.backGroundColor

        circleLabel.backgroundColor = UIColor(hex: "#000000", alpha: 0)
        circleLabel.layer.cornerRadius = self.circleLabel.frame.size.width / 2
        circleLabel.clipsToBounds = false // TO_DO: burası true olsa ne olur
        circleLabel.layer.borderWidth = 2.0
        circleLabel.layer.borderColor = UIColor.white.cgColor

        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
        tapGesture.numberOfTapsRequired = 1
        window?.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:)))
        window?.addGestureRecognizer(panGesture)
        setListeners()
        
    }
    
    func setListeners() {
        closeButton.setOnClickedListener { [self] in
            delegate?.notificationShouldDismiss(controller: self,
                                                callToActionURL: nil,
                                                shouldTrack: true,
                                                additionalTrackingProperties: nil)
        }
    }
    
    fileprivate func setWindowAndAddAnimation(_ animated: Bool) {
        if let window = window {
            window.windowLevel = UIWindow.Level.alert
            window.clipsToBounds = true
            window.rootViewController = self
            window.layer.cornerRadius = 6

            // TO_DO: bunları default set ediyorum doğru mudur?
            window.layer.borderColor = UIColor.white.cgColor
            window.layer.borderWidth = 1
            window.isHidden = false
        }

        let duration = animated ? 0.1 : 0
        UIView.animate(withDuration: duration, animations: {
            
            if self.isTop {
                self.window?.frame.origin.y += (RDInAppNotificationsConstants.miniInAppHeight
                                                    + RDInAppNotificationsConstants.miniBottomPadding)
            } else {
                self.window?.frame.origin.y -= (RDInAppNotificationsConstants.miniInAppHeight
                                                    + RDInAppNotificationsConstants.miniBottomPadding)
            }
            

            self.canPan = true
        }, completion: { _ in
            self.position = self.window?.layer.position
        })
    }

    override func show(animated: Bool) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication() else {
            return
        }
        canPan = false
        var bounds: CGRect
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                           .connectedScenes
                           .filter { $0.activationState == .foregroundActive }
                           .first
            guard let scene = windowScene as? UIWindowScene else { return }
            bounds = scene.coordinateSpace.bounds
        } else {
            bounds = UIScreen.main.bounds
        }
        let frame: CGRect
        if sharedUIApplication.statusBarOrientation.isPortrait
            && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            
            if notification?.pos == "top" {
                frame = CGRect(x: RDInAppNotificationsConstants.miniSidePadding,
                               y: -RDInAppNotificationsConstants.miniInAppHeight+35,
                               width: bounds.size.width - (RDInAppNotificationsConstants.miniSidePadding * 2),
                               height: RDInAppNotificationsConstants.miniInAppHeight)
            } else {
                frame = CGRect(x: RDInAppNotificationsConstants.miniSidePadding,
                               y: bounds.size.height-15,
                               width: bounds.size.width - (RDInAppNotificationsConstants.miniSidePadding * 2),
                               height: RDInAppNotificationsConstants.miniInAppHeight)
            }

        } else { // Is iPad or Landscape mode
            frame = CGRect(x: bounds.size.width / 4,
                           y: bounds.size.height,
                           width: bounds.size.width / 2,
                           height: RDInAppNotificationsConstants.miniInAppHeight)
        }
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first
            if let windowScene = windowScene as? UIWindowScene {
                window = UIWindow(frame: frame)
                window?.windowScene = windowScene
            }
        } else {
            window = UIWindow(frame: frame)
        }

        setWindowAndAddAnimation(animated)
    }

    override func hide(animated: Bool, completion: @escaping () -> Void) {
        if !isDismissing {
            canPan = false
            isDismissing = true
            let duration = animated ? 0.5 : 0
            UIView.animate(withDuration: duration, animations: {
                if self.isTop {
                    self.window?.frame.origin.y -= (RDInAppNotificationsConstants.miniInAppHeight
                                                + RDInAppNotificationsConstants.miniBottomPadding)
                } else {
                    self.window?.frame.origin.y += (RDInAppNotificationsConstants.miniInAppHeight
                                                + RDInAppNotificationsConstants.miniBottomPadding)
                }

                }, completion: { _ in
                    self.window?.isHidden = true
                    self.window?.removeFromSuperview()
                    self.window = nil
                    completion()
            })
        }
    }

    @objc func didTap(gesture: UITapGestureRecognizer) {
        if !isDismissing && gesture.state == UIGestureRecognizer.State.ended {
            delegate?.notificationShouldDismiss(controller: self,
                                                callToActionURL: miniNotification.callToActionUrl,
                                                shouldTrack: true,
                                                additionalTrackingProperties: nil)
        }
    }

    @objc func didPan(gesture: UIPanGestureRecognizer) {
        if canPan, let window = window {
            switch gesture.state {
            case UIGestureRecognizer.State.began:
                panStartPoint = gesture.location(in: RDInstance.sharedUIApplication()?.keyWindow)
            case UIGestureRecognizer.State.changed:
                var position = gesture.location(in: RDInstance.sharedUIApplication()?.keyWindow)
                let diffY = position.y - panStartPoint.y
                position.y = max(position.y, position.y + diffY)
                window.layer.position = CGPoint(x: window.layer.position.x, y: position.y)
            case UIGestureRecognizer.State.ended, UIGestureRecognizer.State.cancelled:
                if window.layer.position.y > position.y + (RDInAppNotificationsConstants.miniInAppHeight / 2) {
                    delegate?.notificationShouldDismiss(controller: self,
                                                        callToActionURL: miniNotification.callToActionUrl,
                                                        shouldTrack: false,
                                                        additionalTrackingProperties: nil)
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        window.layer.position = self.position
                    })
                }
            default:
                break
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard RDInstance.sharedUIApplication() != nil else {
            return
        }
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            let frame: CGRect
            if  UIDevice.current.orientation.isPortrait
                && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
                frame = CGRect(x: RDInAppNotificationsConstants.miniSidePadding,
                               y: UIScreen.main.bounds.size.height -
                                (RDInAppNotificationsConstants.miniInAppHeight
                                + RDInAppNotificationsConstants.miniBottomPadding),
                               width: UIScreen.main.bounds.size.width -
                                (RDInAppNotificationsConstants.miniSidePadding * 2),
                               height: RDInAppNotificationsConstants.miniInAppHeight)
            } else { // Is iPad or Landscape mode
                frame = CGRect(x: UIScreen.main.bounds.size.width / 4,
                               y: UIScreen.main.bounds.size.height -
                                (RDInAppNotificationsConstants.miniInAppHeight
                                + RDInAppNotificationsConstants.miniBottomPadding),
                               width: UIScreen.main.bounds.size.width / 2,
                               height: RDInAppNotificationsConstants.miniInAppHeight)
            }
            self.window?.frame = frame

            }, completion: nil)
    }
}
