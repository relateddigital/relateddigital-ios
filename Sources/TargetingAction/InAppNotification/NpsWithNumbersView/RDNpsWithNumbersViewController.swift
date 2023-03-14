//
//  RDNpsWithNumbersViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit

class RDNpsWithNumbersViewController: UIViewController {

    typealias RDDPNVC = RDDefaultPopupNotificationViewController
    typealias UITGR = UITapGestureRecognizer
    typealias UIPGR = UIPanGestureRecognizer


    fileprivate var initialized = false
    weak var notification: RDInAppNotification?
    
    fileprivate var completion: (() -> Void)?


    /// Returns the controllers view
    internal var popupContainerView: RDNpsWithNumbersContainerView {
        return view as! RDNpsWithNumbersContainerView // swiftlint:disable:this force_cast
    }
    
    public var standardView: RDNpsWithNumbersCollectionView {
        return view as! RDNpsWithNumbersCollectionView // swiftlint:disable:this force_cast
    }

    /// The set of buttons
    fileprivate var buttons = [RDPopupDialogButton]()


    fileprivate func initForInAppNotification(_ viewController: RDDPNVC) {
        guard let _ = self.notification else { return }
    }

    func commonButtonAction() {
        guard let notification = self.notification else { return }
        var returnCallback = true
        var additionalTrackingProperties = Properties()
        
        if let num = self.standardView.selectedNumber {
            additionalTrackingProperties["OM.s_point"] = "\(num)"
        }
        
        additionalTrackingProperties["OM.s_cat"] = notification.type.rawValue
        additionalTrackingProperties["OM.s_page"] = "act-\(notification.actId)"
        
        // Check if second popup coming
        var callToActionURL: URL? = notification.callToActionUrl
        if notification.type == .secondNps {
            callToActionURL = nil
            returnCallback = false
        }
        
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

        let viewController = RDDPNVC(rdInAppNotification: notification, emailForm: nil, scratchToWin: nil)

        self.init(notification: notification,
                  mailForm: nil,
                  scratchToWin: nil,
                  viewController: viewController,
                  buttonAlignment: .vertical,
                  transitionStyle: .zoomIn,
                  preferredWidth: 580,
                  tapGestureDismissal: false,
                  panGestureDismissal: false,
                  hideStatusBar: false)
        initForInAppNotification(viewController)
        self.notification = notification
        viewController.standardView.closeButton.isUserInteractionEnabled = true
        viewController.standardView.imgButtonDelegate = self
        viewController.standardView.npsDelegate = self
    }


    public init(
        notification: RDInAppNotification?,
        mailForm: MailSubscriptionViewModel?,
        scratchToWin: ScratchToWinModel?,
        viewController: UIViewController,
        buttonAlignment: NSLayoutConstraint.Axis = .vertical,
        transitionStyle: PopupDialogTransitionStyle = .bounceUp,
        preferredWidth: CGFloat = 340,
        tapGestureDismissal: Bool = true,
        panGestureDismissal: Bool = true,
        hideStatusBar: Bool = false,
        completion: (() -> Void)? = nil) {

            self.completion = completion
            super.init(nibName: nil, bundle: nil)
            self.notification = notification
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
            if !(notification?.secondButtonText.isNilOrWhiteSpace ?? false) {
                popupContainerView.buttonStackView.axis = .horizontal
                popupContainerView.buttonStackView.spacing = 5
            } else {
                popupContainerView.buttonStackView.axis = buttonAlignment
            }
            viewController.didMove(toParent: self)

            // Allow for dialog dismissal on background tap
            if tapGestureDismissal {
                let tapRecognizer = UITGR(target: self, action: #selector(handleTap))
                tapRecognizer.cancelsTouchesInView = false
                popupContainerView.addGestureRecognizer(tapRecognizer)
            }

        }

    // Init with coder not implemented
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle

    /// Replaces controller view with popup view
    public override func loadView() {
        view = RDNpsWithNumbersContainerView(frame: UIScreen.main.bounds, preferredWidth: UIScreen.main.bounds.width)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
        guard !initialized else { return }
        if let not = notification, !not.buttonText.isNilOrWhiteSpace {
            appendButtons()
        }
        initialized = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.15) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
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

        if notification?.type == .imageTextButton {
            buttonStackView.distribution = .fillProportionally
            buttonStackView.axis = .horizontal
            // başlangıç boslugu
            let leadingSpacerView = UIView()
            leadingSpacerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([leadingSpacerView.widthAnchor.constraint(equalToConstant: fakeSpace)])
            buttonStackView.addArrangedSubview(leadingSpacerView)

            let stackViewButtons = UIStackView()
            stackViewButtons.translatesAutoresizingMaskIntoConstraints = false
            stackViewButtons.axis = .horizontal
            stackViewButtons.distribution = .fillEqually
            stackViewButtons.spacing = 5
            buttonStackView.addArrangedSubview(stackViewButtons)
            for (index, button) in buttons.enumerated() {
                button.needsLeftSeparator = buttonStackView.axis == .horizontal && index > 0
                stackViewButtons.addArrangedSubview(button)
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            }

            // Bitiş boslugu
            let trailingSpacerView = UIView()
            trailingSpacerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([trailingSpacerView.widthAnchor.constraint(equalToConstant: fakeSpace)])
            buttonStackView.addArrangedSubview(trailingSpacerView)

            // taban boslugu
            let bottomSpacerView = UIView()
            bottomSpacerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([bottomSpacerView.heightAnchor.constraint(equalToConstant: fakeSpace / 2)])
            stackView.addArrangedSubview(bottomSpacerView)
        } else {

            for (index, button) in buttons.enumerated() {
                button.needsLeftSeparator = buttonStackView.axis == .horizontal && index > 0
                buttonStackView.addArrangedSubview(button)
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            }
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

internal extension RDNpsWithNumbersViewController {
    // MARK: - Keyboard & orientation observers

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self,
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
    func urlClicked( _ url: URL)
}

