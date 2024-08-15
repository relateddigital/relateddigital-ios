//
//  RDClowMachineBannerController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 15.08.2024.
//

import UIKit

class RDClawMachineBannerController: RDBaseNotificationViewController {
    
    var ClawMachineCodeBannerView: RDClawMachineCodeBannerView!
    var halfScreenHeight = 0.0
    
    var isDismissing = false
    
    init(_ clawMachineModel: ClawMachineModel) {
        super.init(nibName: nil, bundle: nil)
        self.ClawMachine = clawMachineModel
        ClawMachineCodeBannerView = RDClawMachineCodeBannerView(frame: UIScreen.main.bounds, clawMachineModel:  self.ClawMachine!)
        view = ClawMachineCodeBannerView
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
        tapGesture.numberOfTapsRequired = 1
        ClawMachineCodeBannerView.addGestureRecognizer(tapGesture)
        
        let closeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped(tapGestureRecognizer:)))
        ClawMachineCodeBannerView.closeButton.isUserInteractionEnabled = true
        ClawMachineCodeBannerView.closeButton.addGestureRecognizer(closeTapGestureRecognizer)
    }


    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func didTap(gesture: UITapGestureRecognizer) {
        if !isDismissing && gesture.state == UIGestureRecognizer.State.ended {
            UIPasteboard.general.string = ClawMachine?.promocode_banner_text.replacingOccurrences(of: "\'", with: "")
            RDHelper.showCopiedClipboardMessage()
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
        
        let topInset = Double(RDHelper.getSafeAreaInsets().top)
        halfScreenHeight = Double(ClawMachineCodeBannerView.horizontalStackView.frame.height)
        
        let frameY = topInset
        
        
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
                
                let originY  = -(self.halfScreenHeight + Double(RDHelper.getSafeAreaInsets().top))

                
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
