//
//  RDNpsWithNumbersViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit
import AVFoundation

class RDNpsWithNumbersViewController: UIViewController {
    
    var player : AVPlayer?
        
    weak var notification: RDInAppNotification?
    
    fileprivate var completion: (() -> Void)?
    
    internal var npsContainerView: RDNpsWithNumbersContainerView {
        return view as! RDNpsWithNumbersContainerView  // swiftlint:disable:this force_cast
    }
    
    public var collectionView: RDNpsWithNumbersCollectionView!
    
    fileprivate var button: RDPopupDialogButton?
        
    func commonButtonAction() {
        guard let notification = self.notification else { return }
        var returnCallback = true
        var additionalTrackingProperties = Properties()
        
        if let num = collectionView.selectedNumber {
            additionalTrackingProperties["OM.s_point"] = "\(num)"
        }
        additionalTrackingProperties["OM.s_cat"] = notification.type.rawValue
        additionalTrackingProperties["OM.s_page"] = "act-\(notification.actId)"
        
        // Check if second popup coming
        var callToActionURL: URL? = notification.callToActionUrl
        /*
         self.delegate?.notificationShouldDismiss(controller: self,
         callToActionURL: callToActionURL,
         shouldTrack: true,
         additionalTrackingProperties: additionalTrackingProperties)
         */
        
        if returnCallback {
            
            if notification.buttonFunction == RDConstants.copyRedirect {
                if let promoCode = notification.promotionCode {
                    UIPasteboard.general.string = promoCode
                    RDHelper.showCopiedClipboardMessage()
                }
            }
            //self.inappButtonDelegate?.didTapButton(notification)
        }
    }
    
    public init(notification: RDInAppNotification? = nil) {
        self.notification = notification
        super.init(nibName: nil, bundle: nil)
        npsContainerView.buttonStackView.accessibilityIdentifier = "buttonStack"
        if let backgroundColor = notification?.backGroundColor {
            npsContainerView.shadowContainer.backgroundColor = backgroundColor
        }        
        npsContainerView.buttonStackView.axis = .vertical
                
        guard let notification = self.notification else { return }
        button = RDPopupDialogButton(
            title: notification.buttonText!,
            font: notification.buttonTextFont,
            buttonTextColor: notification.buttonTextColor,
            buttonColor: notification.buttonColor, action: commonButtonAction,
            buttonCornerRadius: Double(notification.buttonBorderRadius ?? "0") ?? 0)
        button!.isEnabled = false
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle
    
    /// Replaces controller view with popup view
    public override func loadView() {
        view = RDNpsWithNumbersContainerView(frame: UIScreen.main.bounds, notification: notification!)
        collectionView = RDNpsWithNumbersCollectionView(frame: UIScreen.main.bounds, rdInAppNotification: notification)
        npsContainerView.stackView.insertArrangedSubview(collectionView, at: 0)
        collectionView.npsDelegate = self
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appendButtons()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        player = collectionView.imageView.addVideoPlayer(urlString: notification?.videourl ?? "")
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if notification?.videourl?.count ?? 0 > 0 {
            collectionView.imageHeightConstraint?.constant = collectionView.imageView.pv_heightForImageView(isVideoExist: true)
        } else {
            let a = collectionView.imageView.pv_heightForImageView(isVideoExist: false)
            print(a)
            collectionView.imageHeightConstraint?.constant = a // standardView.imageView.pv_heightForImageView(isVideoExist: false)
            collectionView.imageHeightConstraint?.isActive = true
            collectionView.imageView.height(a)
        }
    }
    
    deinit {
        completion?()
        completion = nil
    }
    
    // MARK: - Dismissal related

    @objc public func dismiss(_ completion: (() -> Void)? = nil) {
        dismiss(animated: true) {
            completion?()
        }
    }
    
    // MARK: - Button related
    
    fileprivate func appendButtons() {
        let stackView = npsContainerView.stackView
        let buttonStackView = npsContainerView.buttonStackView
        
        if button == nil {
            stackView.removeArrangedSubview(npsContainerView.buttonStackView)
        }
        
        button!.needsLeftSeparator = buttonStackView.axis == .horizontal
        buttonStackView.addArrangedSubview(button!)
        button!.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
    }
    

    @objc fileprivate func buttonTapped(_ button: RDPopupDialogButton) {
        button.buttonAction?()
    }
    
    
}


extension RDNpsWithNumbersViewController: NPSDelegate {
    
    func ratingSelected() {
        if let button = button {
            button.isEnabled = true
        }
    }
    
    func ratingUnselected() {
        if let button = button {
            button.isEnabled = false
        }
    }
    
}

/*
@objc
public protocol RDNpsWithNumbersViewURLDelegate: NSObjectProtocol {
    @objc
    func urlClicked(_ url: URL)
}
*/
