//
//  RDPopupDialogDefaultView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation
import UIKit

public class RDPopupDialogDefaultView: UIView {

    typealias NSLC = NSLayoutConstraint

    // MARK: - VARIABLES

    internal lazy var closeButton = setCloseButton()
    internal lazy var imageView = setImageView()
    internal lazy var secondImageView = setSecondImageView()
    internal lazy var titleLabel = setTitleLabel()
    internal lazy var copyCodeTextButton = setCopyCodeText()
    internal lazy var promoCodeFunction = getPromoCodeFunction()
    internal lazy var copyCodeImageButton = setCopyCodeImage()
    internal lazy var copyCodeButtonWithText = setCopyCodeButtonWithText()
    internal lazy var messageLabel = setMessageLabel()
    internal lazy var npsView = setNpsView()

    internal lazy var emailTF = setEmailTF()
    internal lazy var firstCheckBox = setCheckbox()
    internal lazy var secondCheckBox = setCheckbox()

    internal lazy var termsButton = setTermsButton()
    internal lazy var consentButton = setConsentButton()

    internal lazy var resultLabel = setResultLabel()
    internal lazy var sliderStepRating = setSliderStepRating()
    internal lazy var numberRating = setNumberRating()

    internal var sctw: ScratchUIView!
    internal var sctwButton: RDPopupDialogButton!
    internal lazy var feedbackTF = setFeedbackTF()
    internal lazy var imageButton = setImageButton()

    var colors: [[CGColor]] = []
    var numberBgColor: UIColor = .black
    var numberBorderColor: UIColor = .white
    var selectedNumber: Int?
    var expanded = false
    var sctwMail: String = ""

    internal var imageHeightConstraint: NSLC?
    internal var secondImageHeight: NSLC?

    weak var rdInAppNotification: RDInAppNotification?
    var emailForm: MailSubscriptionViewModel?
    var scratchToWin: ScratchToWinModel?
    var consentCheckboxAdded = false
    weak var imgButtonDelegate: ImageButtonImageDelegate?
    weak var delegate: RDPopupDialogDefaultViewDelegate?
    weak var inappButtonDelegate: RDInappButtonDelegate?
    weak var npsDelegate: NPSDelegate?
    weak var NVCdelegate: RDNotificationViewControllerDelegate?
    // MARK: - CONSTRUCTOR
    init(frame: CGRect, rdInAppNotification: RDInAppNotification?,
                        emailForm: MailSubscriptionViewModel? = nil,
                        scratchTW: ScratchToWinModel? = nil) {
        self.rdInAppNotification = rdInAppNotification
        self.emailForm = emailForm
        self.scratchToWin = scratchTW
        super.init(frame: frame)
        if self.rdInAppNotification != nil {
            setupViews()
        } else if self.emailForm != nil {
            setupInitialViewForEmailForm()
        } else {
            setupInitialForScratchToWin()
        }
    }

    func setupInitialViewForEmailForm() {
        guard let model = self.emailForm else { return }
        titleLabel.text = model.title.removeEscapingCharacters()
        titleLabel.font = model.titleFont
        titleLabel.textColor = model.titleColor

        messageLabel.text = model.message.removeEscapingCharacters()
        messageLabel.font = model.messageFont
        messageLabel.textColor = model.textColor

        closeButton.setTitleColor(model.closeButtonColor, for: .normal)
        self.backgroundColor = model.backgroundColor

        self.addSubview(imageView)
        self.addSubview(closeButton)

        var constraints = [NSLC]()
        imageHeightConstraint = NSLC(item: imageView,
            attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 0, constant: 0)

        if let imageHeightConstraint = imageHeightConstraint {
            constraints.append(imageHeightConstraint)
        }

        closeButton.trailing(to: self, offset: -10.0)
        NSLC.activate(constraints)

        setupForEmailForm()
    }

    fileprivate func createSctwAndAddSubview(_ model: ScratchToWinModel) {
        let frame = CGRect(x: 0, y: 0, width: 280.0, height: 50.0)
        let coupon = UIView(frame: frame)
        coupon.backgroundColor = .white

        let cpLabel = UILabel(frame: frame)
        cpLabel.font = model.promoFont
        cpLabel.text = model.promocode
        cpLabel.textAlignment = .center
        cpLabel.textColor = model.promoTextColor
        coupon.addSubview(cpLabel)

        let couponImg = coupon.asImage()

        let maskView = UIView(frame: frame)
        maskView.backgroundColor = model.scratchColor

        let maskImg = maskView.asImage()

        self.sctw = ScratchUIView(frame: frame, couponImage: couponImg, maskImage: maskImg, scratchWidth: 20.0)
        sctw.delegate = self
        self.addSubview(sctw)
    }

    fileprivate func addSctwMailForm(_ model: ScratchToWinModel) {
        sctwButton = RDPopupDialogButton(title: model.mailButtonText ?? "",
                                               font: model.mailButtonFont ?? .systemFont(ofSize: 20),
                                               buttonTextColor: model.mailButtonTextColor,
                                               buttonColor: model.mailButtonColor, action: nil)
        sctwButton.addTarget(self, action: #selector(collapseSctw), for: .touchDown)

        sctw.isUserInteractionEnabled = false
        addSubview(sctwButton)
        sctwButton.height(50.0)
        sctwButton.allEdges(to: self, excluding: .top)

        addSubview(firstCheckBox)
        addSubview(secondCheckBox)
        addSubview(emailTF)
        addSubview(termsButton)
        addSubview(consentButton)
        addSubview(resultLabel)

        emailTF.placeholder = model.placeholder
        emailTF.delegate = self
        emailTF.topToBottom(of: sctw, offset: 20)
        emailTF.leading(to: self, offset: 10)
        emailTF.trailing(to: self, offset: -10)
        emailTF.height(25)

        resultLabel.topToBottom(of: emailTF, offset: 8.0)
        resultLabel.leading(to: self, offset: 10)
        resultLabel.trailing(to: self, offset: -10)
        resultLabel.height(12)

        firstCheckBox.topToBottom(of: resultLabel, offset: 8.0)
        firstCheckBox.leading(to: self, offset: 10)
        firstCheckBox.size(CGSize(width: 20, height: 20))
        termsButton.leadingToTrailing(of: firstCheckBox, offset: 10)
        termsButton.centerY(to: firstCheckBox)

        secondCheckBox.topToBottom(of: firstCheckBox, offset: 5)
        secondCheckBox.leading(to: self, offset: 10)
        secondCheckBox.size(CGSize(width: 20, height: 20))

        consentButton.leadingToTrailing(of: secondCheckBox, offset: 10)
        consentButton.centerY(to: secondCheckBox)

        let parsedPermit = model.permitText ?? ParsedPermissionString(string: "Click here to read terms & conditions.", location: 5, length: 6)
        let parsedConsent = model.consentText ?? ParsedPermissionString(string: "Click here to read terms & conditions.", location: 5, length: 6)
        let attrPermit = NSMutableAttributedString(string: parsedPermit.string)
        let attrCon = NSMutableAttributedString(string: parsedConsent.string)
        attrPermit.addAttribute(.link, value: model.permitUrl ?? "",
                             range: NSRange(location: parsedPermit.location, length: parsedPermit.length))
        attrCon.addAttribute(.link, value: model.consentUrl ?? "",
                             range: NSRange(location: parsedConsent.location, length: parsedConsent.length))

        termsButton.setAttributedTitle(attrPermit, for: .normal)
        termsButton.setTitle(parsedPermit.string, for: .normal)
        termsButton.titleLabel?.font = model.emailPermitTextFont ?? .systemFont(ofSize: 12)
        consentButton.setAttributedTitle(attrCon, for: .normal)
        consentButton.setTitle(parsedConsent.string, for: .normal)
        consentButton.titleLabel?.font = model.consentTextFont ?? .systemFont(ofSize: 12)

        sctwButton.topToBottom(of: secondCheckBox, offset: 10)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func setupInitialForScratchToWin() {
        guard let model = self.scratchToWin else { return }
        var imageAdded = false
        if model.imageUrl != nil {
            addSubview(imageView)
            imageView.allEdges(to: self, excluding: .bottom)
            imageView.setImage(withUrl: model.imageUrl)
            imageAdded = true
        }
        titleLabel.text = model.title?.removeEscapingCharacters()
        titleLabel.font = model.titleFont
        titleLabel.textColor = model.titleTextColor

        messageLabel.text = model.message?.removeEscapingCharacters()
        messageLabel.font = model.messageFont
        messageLabel.textColor = model.messageTextColor

        closeButton.setTitleColor(model.closeButtonColor, for: .normal)
        self.backgroundColor = model.backgroundColor

        self.addSubview(closeButton)
        self.addSubview(titleLabel)
        self.addSubview(messageLabel)

        if imageAdded {
            self.titleLabel.topToBottom(of: imageView, offset: 10)
        } else {
            self.titleLabel.top(to: self, offset: 50)
        }
        self.titleLabel.leading(to: self)
        self.titleLabel.trailing(to: self)
        self.messageLabel.topToBottom(of: titleLabel, offset: 10)
        self.messageLabel.leading(to: self)
        self.messageLabel.trailing(to: self)

        createSctwAndAddSubview(model)

        sctw.topToBottom(of: messageLabel, offset: 20)
        sctw.width(280.0)
        sctw.height(50.0)

        if model.hasMailForm {
            addSctwMailForm(model)
        } else {
            sctw.bottom(to: self, offset: -60)
        }

        self.closeButton.trailing(to: self, offset: -10)

        var constraints = [NSLC]()
        imageHeightConstraint = NSLC(item: imageView,
            attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 0, constant: 0)

        if let imageHeightConstraint = imageHeightConstraint {
            constraints.append(imageHeightConstraint)
        }

        NSLC.activate(constraints)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func setupViews() {

        guard let notification = rdInAppNotification else {
            return
        }

        baseSetup(notification)

        var constraints = [NSLC]()
        switch notification.type {
        case .imageButton, .fullImage:
            imageView.allEdges(to: self)
        case .imageTextButton:
            setupForImageTextButton()
        case .nps:
            setupForNps()
        case .smileRating:
            setupForSmileRating()
        case .emailForm:
            setupForEmailForm()
        case .npsWithNumbers:
            setupForNpsWithNumbers()
        case .secondNps:
            setupForNps()
            closeButton.isHidden = true
        case .feedbackForm:
            setupForImageTextButton(true)
        case .imageButtonImage:
            setupForImageButtonImage()
        default:
            setupForDefault()
        }

        imageHeightConstraint = NSLC(item: imageView,
            attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 0, constant: 0)

        if let imageHeightConstraint = imageHeightConstraint {
            constraints.append(imageHeightConstraint)
        }
        secondImageHeight = NSLC(item: secondImageView,
                                               attribute: .height, relatedBy: .equal, toItem: secondImageView, attribute: .height, multiplier: 0, constant: 0)
        if let secondHeight = secondImageHeight {
            constraints.append(secondHeight)
        }
        closeButton.trailing(to: self, offset: -10.0)
        NSLC.activate(constraints)
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        emailTF.resignFirstResponder()
    }
}

// MARK: - SliderStepDelegate

extension RDPopupDialogDefaultView: SliderStepDelegate {
    func didSelectedValue(sliderStep: RDSliderStep, value: Float) {
        sliderStep.value = value
    }
}

// Email form extension
extension RDPopupDialogDefaultView {

    @objc func termsButtonTapped(_ sender: UIButton) {
        if let url = scratchToWin?.permitUrl {
            RDInstance.sharedUIApplication()?.open(url, options: [:], completionHandler: nil)
        }
        if let url = emailForm?.emailPermitUrl {
            RDInstance.sharedUIApplication()?.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc func copyCodeTextButtonTapped(_ sender: UIButton) {
        UIPasteboard.general.string = copyCodeTextButton.currentTitle
        RDHelper.showCopiedClipboardMessage()
        if getPromoCodeFunction() == "copy_close" {
            RDHelper.showCopiedClipboardMessage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.delegate?.dismissPromo()
            }
        }
    }

    @objc func consentButtonTapped(_ sender: UIButton) {
        if let url = scratchToWin?.consentUrl {
            RDInstance.sharedUIApplication()?.open(url, options: [:], completionHandler: nil)
        }
        if let url = emailForm?.consentUrl {
            RDInstance.sharedUIApplication()?.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension RDPopupDialogDefaultView: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    public func textFieldDidEndEditing(_ textField: UITextField) {

    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.rdInAppNotification?.type == .emailForm {
            return emailTF.resignFirstResponder()
        } else {
            return feedbackTF.resignFirstResponder()
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                                as? NSValue)?.cgRectValue {
            if let view = getTopView() {
                if view.frame.origin.y == 0 {
                    view.frame.origin.y -= keyboardSize.height
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if let view = getTopView() {
            if view.frame.origin.y != 0 {
                view.frame.origin.y = 0
            }
        }
    }

    func getTopView() -> UIView? {
        var topView: UIView?
        let window = UIApplication.shared.keyWindow
        if window != nil {
            for subview in window?.subviews ?? [] {
                if !subview.isHidden && subview.alpha > 0
                    && subview.frame.size.width > 0
                    && subview.frame.size.height > 0 {
                    topView = subview
                }
            }
        }
        return topView
    }

    @objc func collapseSctw() {
        DispatchQueue.main.async { [self] in
            let email = self.emailTF.text ?? ""

            if !RDHelper.checkEmail(email: email) {
                self.resultLabel.text = self.scratchToWin?.invalidEmailMessage
                self.resultLabel.isHidden = false
            } else if !self.firstCheckBox.isChecked || !self.secondCheckBox.isChecked {
                self.resultLabel.text = self.scratchToWin?.checkConsentText
                self.resultLabel.isHidden = false
            } else {
                self.sctwMail = emailTF.text ?? ""
                self.resultLabel.text = self.scratchToWin?.successMessage
                self.resultLabel.textColor = .green
                self.resultLabel.topToBottom(of: self.sctw, offset: 10.0)
                self.resultLabel.isHidden = false
                self.hideResultLabel()
                self.sctw.isUserInteractionEnabled = true
                self.emailTF.removeFromSuperview()
                self.termsButton.removeFromSuperview()
                self.consentButton.removeFromSuperview()
                self.firstCheckBox.removeFromSuperview()
                self.secondCheckBox.removeFromSuperview()
                self.sctwButton.removeFromSuperview()
                self.sctw.bottom(to: self, offset: -60)
                self.setNeedsLayout()
                self.setNeedsDisplay()
            }
        }
    }

    func hideResultLabel() {
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.resultLabel.removeFromSuperview()
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }

    @objc func expandSctw() {
        let model = self.scratchToWin!
        sctwButton = RDPopupDialogButton(title: model.copyButtonText ?? "",
                                               font: model.copyButtonTextFont ?? .systemFont(ofSize: 20),
                                                            buttonTextColor: model.copyButtonTextColor,
                                                            buttonColor: model.copyButtonColor, action: nil)
        addSubview(sctwButton)
        sctwButton.addTarget(self, action: #selector(copyCodeAndDismiss), for: .touchDown)
        let actid = String(scratchToWin?.actId ?? 0)
        let auth = scratchToWin?.auth ?? ""

        RelatedDigital.trackScratchToWinClick(scratchToWinReport: (self.scratchToWin?.report)!)
        RelatedDigital.subscribeSpinToWinMail(actid: actid, auth: auth, mail: sctwMail)
        sctwButton.allEdges(to: self, excluding: .top)
        sctwButton.height(50)
    }

    @objc func dismissKeyboard() {
        self.endEditing(true)
    }

    @objc func copyCodeAndDismiss() {
        UIPasteboard.general.string = scratchToWin?.promocode
        RDHelper.showCopiedClipboardMessage()
        DispatchQueue.main.async {
            if let url = URL(string: self.scratchToWin?.iosLink ?? "") {
                UIApplication.shared.open(url)
            }
        }
        self.delegate?.dismissSctw()
    }
}

extension RDPopupDialogDefaultView: ScratchUIViewDelegate {
    public func scratchMoved(_ view: ScratchUIView) {
        if !expanded && view.getScratchPercent() > 0.69 {
            expanded = true
            expandSctw()
        }
    }
}

protocol RDPopupDialogDefaultViewDelegate: AnyObject {
    func dismissSctw()
    func dismissPromo()
}

protocol ImageButtonImageDelegate: AnyObject {
    func imageButtonTapped()
}

protocol NPSDelegate: AnyObject {
    func ratingSelected()
    func ratingUnselected()
}

class inAppCurrentState {
    static var shared = inAppCurrentState()
    var isFirstPageOpened = false
}
