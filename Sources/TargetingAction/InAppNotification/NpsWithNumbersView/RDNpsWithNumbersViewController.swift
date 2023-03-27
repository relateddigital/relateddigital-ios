//
//  RDNpsWithNumbersViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit

class RDNpsWithNumbersViewController: UIViewController {
    
    typealias RDNWNDVC = RDNpsWithNumbersDefaultViewController
    
    fileprivate var initialized = false
    weak var notification: RDInAppNotification?
    
    fileprivate var completion: (() -> Void)?
    
    internal var npsContainerView: RDNpsWithNumbersContainerView {
        return view as! RDNpsWithNumbersContainerView  // swiftlint:disable:this force_cast
    }
    
    public var standardView: RDNpsWithNumbersCollectionView {
        return view as! RDNpsWithNumbersCollectionView  // swiftlint:disable:this force_cast
    }
    
    fileprivate var button: RDPopupDialogButton?
    
    public var viewController: RDNWNDVC
    
    func commonButtonAction() {
        guard let notification = self.notification else { return }
        var returnCallback = true
        var additionalTrackingProperties = Properties()
        
        if let num = viewController.standardView.selectedNumber {
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
        let viewController = RDNWNDVC(rdInAppNotification: notification)
        self.notification = notification
        self.viewController = viewController
        super.init(nibName: nil, bundle: nil)
        npsContainerView.buttonStackView.accessibilityIdentifier = "buttonStack"
        if let backgroundColor = notification?.backGroundColor {
            npsContainerView.container.backgroundColor = backgroundColor
        }
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
        addChild(viewController)
        npsContainerView.stackView.insertArrangedSubview(viewController.view, at: 0)
        npsContainerView.buttonStackView.axis = .vertical
        viewController.didMove(toParent: self)
        
        guard let notification = self.notification else { return }
        button = RDPopupDialogButton(
            title: notification.buttonText!,
            font: notification.buttonTextFont,
            buttonTextColor: notification.buttonTextColor,
            buttonColor: notification.buttonColor, action: commonButtonAction,
            buttonCornerRadius: Double(notification.buttonBorderRadius ?? "0") ?? 0)
        button!.isEnabled = false
        
        viewController.standardView.npsDelegate = self
    }
    

    
    // Init with coder not implemented
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle
    
    /// Replaces controller view with popup view
    public override func loadView() {
        view = RDNpsWithNumbersContainerView(
            frame: UIScreen.main.bounds, preferredWidth: UIScreen.main.bounds.width)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //guard !initialized else { return }
        //if let not = self.notification, !not.buttonText.isNilOrWhiteSpace {
        //    appendButtons()
        //}
        appendButtons()
        initialized = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
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
    
    
    // MARK: - StatusBar display related
    
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
}

extension RDNpsWithNumbersViewController {
    
    @objc public var buttonAlignment: NSLayoutConstraint.Axis {
        get {
            return npsContainerView.buttonStackView.axis
        }
        set {
            npsContainerView.buttonStackView.axis = newValue
            npsContainerView.pv_layoutIfNeededAnimated()
        }
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

@objc
public protocol RDNpsWithNumbersViewURLDelegate: NSObjectProtocol {
    @objc
    func urlClicked(_ url: URL)
}
