//
//  RDHalfScreenViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.11.2021.
//

import UIKit
import AVFoundation

class RDHalfScreenViewController: RDBaseNotificationViewController {
    
    var halfScreenNotification: RDInAppNotification! {
        return super.notification
    }
    
    var player : AVPlayer?
    var relatedDigitalHalfScreenView: RDHalfScreenView!
    var halfScreenHeight = 0.0
    
    var isDismissing = false
    
    init(notification: RDInAppNotification) {
        super.init(nibName: nil, bundle: nil)
        self.notification = notification
        relatedDigitalHalfScreenView = RDHalfScreenView(frame: UIScreen.main.bounds, notification: halfScreenNotification)
        view = relatedDigitalHalfScreenView
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
        tapGesture.numberOfTapsRequired = 1
        relatedDigitalHalfScreenView.addGestureRecognizer(tapGesture)
        
        let closeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped(tapGestureRecognizer:)))
        relatedDigitalHalfScreenView.closeButton.isUserInteractionEnabled = true
        relatedDigitalHalfScreenView.closeButton.addGestureRecognizer(closeTapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player = relatedDigitalHalfScreenView.imageView.addVideoPlayer(urlString: notification?.videourl ?? "")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    @objc func didTap(gesture: UITapGestureRecognizer) {
        if !isDismissing && gesture.state == UIGestureRecognizer.State.ended {
            delegate?.notificationShouldDismiss(controller: self,
                                                callToActionURL: halfScreenNotification.callToActionUrl,
                                                shouldTrack: true,
                                                additionalTrackingProperties: nil)
        }
    }
    
    @objc func closeButtonTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        dismiss(animated: true) {
            self.delegate?.notificationShouldDismiss(controller: self,
                                                     callToActionURL: nil,
                                                     shouldTrack: false,
                                                     additionalTrackingProperties: nil)
        }
    }
    
    override func show(animated: Bool) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication() else {
            return
        }
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
        
        let bottomInset = Double(RDHelper.getSafeAreaInsets().bottom)
        let topInset = Double(RDHelper.getSafeAreaInsets().top)
        halfScreenHeight = Double(relatedDigitalHalfScreenView.imageView.frame.height) + Double(relatedDigitalHalfScreenView.titleLabel.frame.height)
        
        let frameY = halfScreenNotification.position == .bottom ? Double(bounds.size.height) - (halfScreenHeight + bottomInset) : topInset
        
        
        let frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(frameY)), size: CGSize(width: bounds.size.width, height: CGFloat(halfScreenHeight)))
        
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
        
        if let window = window {
            window.windowLevel = UIWindow.Level.alert
            window.clipsToBounds = false // true
            window.rootViewController = self
            window.isHidden = false
        }
    }
    
    override func hide(animated: Bool, completion: @escaping () -> Void) {
        if !isDismissing {
            isDismissing = true
            let duration = animated ? 0.5 : 0
            
            UIView.animate(withDuration: duration, animations: {
                
                var originY = 0.0
                if self.halfScreenNotification.position == .bottom {
                    originY = self.halfScreenHeight + Double(RDHelper.getSafeAreaInsets().bottom)
                } else {
                    originY = -(self.halfScreenHeight + Double(RDHelper.getSafeAreaInsets().top))
                }
                
                self.window?.frame.origin.y += CGFloat(originY)
            }, completion: { _ in
                self.window?.isHidden = true
                self.window?.removeFromSuperview()
                self.window = nil
                completion()
            })
        }
    }
    
}
