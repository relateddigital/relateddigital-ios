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
    typealias UITGR = UITapGestureRecognizer
    
    fileprivate var initialized = false
    weak var notification: RDInAppNotification?
    
    fileprivate var completion: (() -> Void)?
    
    /// Returns the controllers view
    internal var popupContainerView: RDNpsWithNumbersContainerView {
        return view as! RDNpsWithNumbersContainerView  // swiftlint:disable:this force_cast
    }
    
    public var standardView: RDNpsWithNumbersCollectionView {
        return view as! RDNpsWithNumbersCollectionView  // swiftlint:disable:this force_cast
    }
    
    /// The set of buttons
    fileprivate var buttons = [RDPopupDialogButton]()
    
    public var viewController: RDNWNDVC
    
    fileprivate func initForInAppNotification(_ viewController: RDNWNDVC) {
        guard let notification = self.notification else { return }
        let button = RDPopupDialogButton(
            title: notification.buttonText!,
            font: notification.buttonTextFont,
            buttonTextColor: notification.buttonTextColor,
            buttonColor: notification.buttonColor, action: commonButtonAction,
            buttonCornerRadius: Double(notification.buttonBorderRadius ?? "0") ?? 0)
        button.isEnabled = false
        addButton(button)
    }
    
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
    
    public convenience init(notification: RDInAppNotification? = nil) {
        let viewController = RDNWNDVC(rdInAppNotification: notification)
        
        self.init(
            notification: notification,
            viewController: viewController,
            hideStatusBar: false)
        initForInAppNotification(viewController)
        viewController.standardView.npsDelegate = self
    }
    
    public init(
        notification: RDInAppNotification?,
        viewController: UIViewController,
        hideStatusBar: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        self.notification = notification
        self.viewController = viewController as? RDNWNDVC ?? RDNWNDVC()
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        // Init the presentation manager
        popupContainerView.buttonStackView.accessibilityIdentifier = "buttonStack"
        
        if let backgroundColor = notification?.backGroundColor {
            popupContainerView.container.backgroundColor = backgroundColor
        }
        
        modalPresentationStyle = .custom
        
        // StatusBar setup
        modalPresentationCapturesStatusBarAppearance = true
        
        // Add our custom view to the container
        addChild(viewController)
        popupContainerView.stackView.insertArrangedSubview(viewController.view, at: 0)
        popupContainerView.buttonStackView.axis = .vertical
        viewController.didMove(toParent: self)
        
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
        addObservers()
        //guard !initialized else { return }
        appendButtons()
        //if let not = notification, !not.buttonText.isNilOrWhiteSpace {
        //    appendButtons()
        //} else {
        //    print(notification)
        //}
        initialized = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    deinit {
        completion?()
        completion = nil
    }
    
    // MARK: - Dismissal related
    
    @objc fileprivate func handleTap(_ sender: UITGR) {
        let point = sender.location(in: popupContainerView.stackView)
        guard !popupContainerView.stackView.point(inside: point, with: nil) else { return }
        dismiss()
    }
    
    @objc public func dismiss(_ completion: (() -> Void)? = nil) {
        dismiss(animated: true) {
            completion?()
        }
    }
    
    // MARK: - Button related
    
    fileprivate func appendButtons() {
        let stackView = popupContainerView.stackView
        let buttonStackView = popupContainerView.buttonStackView
        
        let fakeSpace = 25.0
        if buttons.isEmpty {
            stackView.removeArrangedSubview(popupContainerView.buttonStackView)
        }
        
        for (index, button) in buttons.enumerated() {
            button.needsLeftSeparator = buttonStackView.axis == .horizontal && index > 0
            buttonStackView.addArrangedSubview(button)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc public func addButton(_ button: RDPopupDialogButton) {
        buttons.append(button)
    }
    
    @objc public func addButtons(_ buttons: [RDPopupDialogButton]) {
        self.buttons += buttons
    }
    
    @objc fileprivate func buttonTapped(_ button: RDPopupDialogButton) {
        button.buttonAction?()
    }
    
    public func tapButtonWithIndex(_ index: Int) {
        let button = buttons[index]
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
            return popupContainerView.buttonStackView.axis
        }
        set {
            popupContainerView.buttonStackView.axis = newValue
            popupContainerView.pv_layoutIfNeededAnimated()
        }
    }
    
}

extension RDNpsWithNumbersViewController {
    // MARK: - Keyboard & orientation observers
    
    func addObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func orientationChanged(_ notification: Notification) {
        
    }
    
}
extension RDNpsWithNumbersViewController: ImageButtonImageDelegate {
    func imageButtonTapped() {
        self.commonButtonAction()
    }
}

extension RDNpsWithNumbersViewController: NPSDelegate {
    
    func ratingSelected() {
        guard let button = self.buttons.first else { return }
        button.isEnabled = true
    }
    
    func ratingUnselected() {
        guard let button = self.buttons.first else { return }
        button.isEnabled = false
    }
    
}

@objc
public protocol RDNpsWithNumbersViewURLDelegate: NSObjectProtocol {
    @objc
    func urlClicked(_ url: URL)
}
