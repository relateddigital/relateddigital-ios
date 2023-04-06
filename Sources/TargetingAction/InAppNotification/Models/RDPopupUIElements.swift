//
//  RDPopupUIElements.swift
//  RelatedDigitalIOS
//
//  Created by Said Alır on 16.03.2021.
//

import Foundation
import UIKit

extension RDPopupDialogDefaultView {
    internal func setCloseButton() -> UIButton {
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.contentHorizontalAlignment = .right
        closeButton.clipsToBounds = false
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 35.0, weight: .regular)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 2.5, right: 2.5)
        return closeButton
    }

    internal func setImageView() -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    internal func setSecondImageView() -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    internal func setTitleLabel() -> UILabel {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(white: 0.4, alpha: 1)
        titleLabel.font = .boldSystemFont(ofSize: 14)
        return titleLabel
    }

    internal func setCopyCodeText() -> UIButton {
        let copyCodeText = UIButton(frame: .zero)
        copyCodeText.translatesAutoresizingMaskIntoConstraints = false
        copyCodeText.setTitle(rdInAppNotification?.promotionCode, for: .normal)
        copyCodeText.backgroundColor = rdInAppNotification?.promotionBackgroundColor
        copyCodeText.setTitleColor(rdInAppNotification?.promotionTextColor, for: .normal)
        copyCodeText.addTarget(self, action: #selector(copyCodeTextButtonTapped(_:)), for: .touchUpInside)

        return copyCodeText
    }

    internal func setCopyCodeImage() -> UIButton {
        let copyCodeImage = UIButton(frame: .zero)
        let copyIconImage = RDHelper.getUIImage(named: "RelatedCopyButton")
        copyCodeImage.setImage(copyIconImage, for: .normal)
        copyCodeImage.translatesAutoresizingMaskIntoConstraints = false
        copyCodeImage.backgroundColor = rdInAppNotification?.promotionBackgroundColor
        copyCodeImage.addTarget(self, action: #selector(copyCodeTextButtonTapped(_:)), for: .touchUpInside)
        return copyCodeImage
    }

    internal func setCopyCodeButtonWithText() -> UIButton {
        let copyCodeButton = UIButton(frame: .zero)
        copyCodeButton.layer.cornerRadius = 5
        copyCodeButton.translatesAutoresizingMaskIntoConstraints = false
        if let color = UIColor(hex: rdInAppNotification?.promocodeCopybuttonColor) {
            copyCodeButton.backgroundColor = color
        }
        if let textColor = UIColor(hex: rdInAppNotification?.promocodeCopybuttonTextColor) {
            copyCodeButton.setTitleColor(textColor, for: .normal)
        }
        copyCodeButton.addTarget(self, action: #selector(copyCodeTextButtonTapped(_:)), for: .touchUpInside)
        copyCodeButton.setTitle(rdInAppNotification?.promocodeCopybuttonText, for: .normal)
        return copyCodeButton
    }

    internal func setMessageLabel() -> UILabel {
        let messageLabel = UILabel(frame: .zero)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = UIColor(white: 0.6, alpha: 1)
        messageLabel.font = .systemFont(ofSize: 14)
        return messageLabel
    }

    internal func setNpsView() -> CosmosView {
        var settings = CosmosSettings()
        settings.filledColor = UIColor.systemYellow
        settings.emptyColor = UIColor.white
        settings.filledBorderColor = UIColor.white
        settings.emptyBorderColor = UIColor.systemYellow
        settings.fillMode = .half
        settings.starSize = 40.0
        settings.disablePanGestures = true
        let npsView = CosmosView(settings: settings)
        npsView.translatesAutoresizingMaskIntoConstraints = false
        npsView.rating = 0.0
        npsView.didFinishTouchingCosmos = { _ in
            self.npsDelegate?.ratingSelected()
        }
        return npsView
    }

    internal func setEmailTF() -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .natural
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .black
        textField.borderStyle = .line
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.layer.borderWidth = 0.5
        textField.tintColor = .systemGray
        textField.delegate = self
        return textField
    }

    internal func setCheckbox() -> Checkbox {
        let check = Checkbox(frame: .zero)
        check.checkmarkStyle = .tick
        check.borderStyle = .square
        check.uncheckedBorderColor = .systemGray
        check.checkedBorderColor = .systemGray
        check.checkmarkColor = .systemGray
        return check
    }

    internal func setTermsButton() -> UIButton {
        let button = UIButton(frame: .zero)
        button.titleLabel?.font = .systemFont(ofSize: 10)
        button.titleLabel?.textColor = .systemGray
        button.addTarget(self, action: #selector(termsButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    internal func setConsentButton() -> UIButton {
        let button = UIButton(frame: .zero)
        button.titleLabel?.font = .systemFont(ofSize: 10)
        button.addTarget(self, action: #selector(consentButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    internal func setResultLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .natural
        label.font = .systemFont(ofSize: 10)
        label.textColor = .red
        return label
    }

    internal func setNumberRating() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 60.0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(RatingCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }

    internal func setFeedbackTF() -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.font = .systemFont(ofSize: 11)
        tf.backgroundColor = .white
        tf.textColor = .black
        tf.delegate = self
        return tf
    }

    internal func setImageButton() -> UIButton {
        let button = UIButton(frame: .zero)
        button.backgroundColor = rdInAppNotification?.buttonColor ?? .black
        button.setTitle(rdInAppNotification?.buttonText, for: .normal)
        button.setTitleColor(rdInAppNotification?.buttonTextColor, for: .normal)
        button.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
        if let buttonCornerRadius = Double(rdInAppNotification?.buttonBorderRadius ?? "0") {
            button.layer.cornerRadius = buttonCornerRadius
        }

        return button
    }

    @objc func imageButtonTapped() {
        print("image button tapped.. should dismiss")
        imgButtonDelegate?.imageButtonTapped()
    }

    internal func setSliderStepRating() -> RDSliderStep {
        let sliderStepRating = RDSliderStep()

        sliderStepRating.stepImages = [getUIImage(named: "terrible")!, getUIImage(named: "bad")!,
                                       getUIImage(named: "okay")!, getUIImage(named: "good")!,
                                       getUIImage(named: "great")!]
        sliderStepRating.tickImages = [getUIImage(named: "unTerrible")!, getUIImage(named: "unBad")!,
                                       getUIImage(named: "unOkay")!, getUIImage(named: "unGood")!,
                                       getUIImage(named: "unGreat")!]

        sliderStepRating.tickTitles = ["Berbat", "Kötü", "Normal", "İyi", "Harika"]

        sliderStepRating.minimumValue = 1
        sliderStepRating.maximumValue = Float(sliderStepRating.stepImages!.count) + sliderStepRating.minimumValue - 1.0
        sliderStepRating.stepTickColor = UIColor.clear
        sliderStepRating.stepTickWidth = 20
        sliderStepRating.stepTickHeight = 20
        sliderStepRating.trackHeight = 2
        sliderStepRating.value = 5
        sliderStepRating.trackColor = .clear
        sliderStepRating.enableTap = true
        sliderStepRating.sliderStepDelegate = self
        sliderStepRating.translatesAutoresizingMaskIntoConstraints = false

        sliderStepRating.contentMode = .redraw // enable redraw on rotation (calls setNeedsDisplay)

        if sliderStepRating.enableTap {
            let tap = UITapGestureRecognizer(target: sliderStepRating,
                                             action: #selector(RDSliderStep.sliderTapped(_:)))
            addGestureRecognizer(tap)
        }

        sliderStepRating.addTarget(sliderStepRating, action: #selector(RDSliderStep.movingSliderStepValue),
                                   for: .valueChanged)
        sliderStepRating.addTarget(sliderStepRating, action: #selector(RDSliderStep.didMoveSliderStepValue),
                                   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return sliderStepRating
    }

    private func getUIImage(named: String) -> UIImage? {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: type(of: self))
        #endif
        return UIImage(named: named, in: bundle, compatibleWith: nil)!.resized(withPercentage: CGFloat(0.75))
    }

    internal func baseSetup(_ notification: RDInAppNotification) {
        if let bgColor = notification.backGroundColor {
            backgroundColor = bgColor
        }

        titleLabel.text = notification.messageTitle?.removeEscapingCharacters()
        titleLabel.font = notification.messageTitleFont
        if let titleColor = notification.messageTitleColor {
            titleLabel.textColor = titleColor
        }
        messageLabel.text = notification.messageBody?.removeEscapingCharacters()
        messageLabel.font = notification.messageBodyFont
        if let bodyColor = notification.messageBodyColor {
            messageLabel.textColor = bodyColor
        }

        if let closeButtonColor = notification.closeButtonColor {
            closeButton.setTitleColor(closeButtonColor, for: .normal)
        }

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        addSubview(closeButton)
    }

    internal func setupForImageTextButton(_ withFeedback: Bool = false) {
        addSubview(titleLabel)
        addSubview(messageLabel)
        imageView.allEdges(to: self, excluding: .bottom)
        // firstPageOpened = true
        titleLabel.topToBottom(of: imageView, offset: 0)
        titleLabel.leading(to: self)
        titleLabel.trailing(to: self)

        if rdInAppNotification?.messageTitle?.count ?? 0 > 0 {
            NSLayoutConstraint.activate([titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)])
        } else {
            NSLayoutConstraint.activate([titleLabel.heightAnchor.constraint(equalToConstant: 0)])
        }

        messageLabel.topToBottom(of: titleLabel, offset: 0)
        messageLabel.leading(to: self)
        messageLabel.trailing(to: self)

        if rdInAppNotification?.messageBody?.count ?? 0 > 0 {
            NSLayoutConstraint.activate([messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)])
        } else {
            NSLayoutConstraint.activate([messageLabel.heightAnchor.constraint(equalToConstant: 0)])
        }

        if rdInAppNotification?.imageUrlString?.isEmpty == true {
            closeButton.layer.zPosition = 1
            closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        }

        if let titleBackgroundColor = rdInAppNotification?.messageTitleBackgroundColor {
            titleLabel.backgroundColor = titleBackgroundColor
        }

        if let bodyBackgroundColor = rdInAppNotification?.messageBodyBackgroundColor {
            messageLabel.backgroundColor = bodyBackgroundColor
        }

        if let promo = rdInAppNotification?.promotionCode,
           let _ = rdInAppNotification?.promotionBackgroundColor,
           let _ = rdInAppNotification?.promotionTextColor,
           !promo.isEmpty {
            addSubview(copyCodeTextButton)
            addSubview(copyCodeButtonWithText)
            copyCodeTextButton.bottom(to: self, offset: -10.0)
            if rdInAppNotification?.messageTitleColor != nil {
                copyCodeTextButton.topToBottom(of: messageLabel, offset: 10)
                copyCodeButtonWithText.topToBottom(of: messageLabel, offset: 10)
            } else {
                copyCodeTextButton.topToBottom(of: messageLabel, offset: 10.0)
                copyCodeButtonWithText.topToBottom(of: messageLabel, offset: 10.0)
            }

            copyCodeButtonWithText.bottom(to: copyCodeTextButton)
            copyCodeTextButton.leading(to: self, offset: 10)
            copyCodeTextButton.layer.cornerRadius = 5
            if rdInAppNotification?.promocodeCopybuttonText?.count ?? 0 > 0 {
                copyCodeButtonWithText.width(80.0)
                copyCodeTextButton.trailingToLeading(of: copyCodeButtonWithText, offset: -10.0)
            } else {
                copyCodeTextButton.trailingToLeading(of: copyCodeButtonWithText, offset: 0.0)
                copyCodeButtonWithText.width(0.0)
                copyCodeButtonWithText.isHidden = true
            }
            copyCodeButtonWithText.height(50.0)
            copyCodeButtonWithText.trailing(to: self, offset: -10)
        } else if withFeedback == false {
            messageLabel.bottom(to: self, offset: -10)
        } else {
            addSubview(feedbackTF)
            feedbackTF.topToBottom(of: messageLabel, offset: 10)
            feedbackTF.leading(to: self, offset: 10)
            feedbackTF.trailing(to: self, offset: -10)
            feedbackTF.bottom(to: self, offset: -10)
            feedbackTF.height(60)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                                   name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                                   name: UIResponder.keyboardWillHideNotification, object: nil)
        }

        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.copyCodeTextButton.setDashedBorder(width: 2, color: .black)
        }
    }

    internal func setupForImageButtonImage() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(imageButton)
        addSubview(secondImageView)

        // firstPageOpened = true
        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)

        imageButton.topToBottom(of: messageLabel, offset: 10.0)
        imageButton.leading(to: self)
        imageButton.trailing(to: self)
        imageButton.height(50.0)

        secondImageView.topToBottom(of: imageButton)
        secondImageView.allEdges(to: self, excluding: .top)
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
    }

    internal func setupForNps() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(npsView)

        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        npsView.topToBottom(of: messageLabel, offset: 10.0)
        npsView.bottom(to: self, offset: -10.0)
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
        npsView.centerX(to: self)
    }

    internal func setupForNpsWithNumbers() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(numberRating)
        numberBorderColor = setBorderColorOfCell()
        guard let numberColors = rdInAppNotification?.numberColors else { return }
        guard let numberRange = rdInAppNotification?.numberRange else { return }
        if numberColors.count == 3 {
            colors = UIColor.getGradientColorArray(numberColors[0], numberColors[1], numberColors[2], numberRange)
        } else if numberColors.count == 2 {
            colors = UIColor.getGradientColorArray(numberColors[0], numberColors[1], numberRange)
        } else {
            numberBgColor = numberColors.first ?? .black
        }

        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        numberRating.topToBottom(of: messageLabel, offset: 10.0)
        numberRating.height(50.0)
        numberRating.leading(to: self, offset: 0)
        numberRating.trailing(to: self, offset: 0)
        numberRating.bottom(to: self, offset: -10.0)
        numberRating.backgroundColor = .clear
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
        numberRating.delegate = self
        numberRating.dataSource = self
    }

    internal func setupForSmileRating() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(sliderStepRating)

        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        sliderStepRating.topToBottom(of: messageLabel, offset: 10.0)
        sliderStepRating.bottom(to: self, offset: -30.0)

        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
        sliderStepRating.centerX(to: self)

        sliderStepRating.leading(to: self, offset: 20.0)
        sliderStepRating.trailing(to: self, offset: -20.0)
    }

    internal func setupForEmailForm() {
        imageView.removeFromSuperview()
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(emailTF)
        addSubview(termsButton)
        addSubview(firstCheckBox)
        addSubview(resultLabel)

        titleLabel.font = emailForm?.titleFont
        messageLabel.font = emailForm?.messageFont

        emailTF.placeholder = emailForm?.placeholder ?? ""
        let parsedPermit = emailForm?.permitText ?? ParsedPermissionString(string: "Click here to read terms & conditions.", location: 5, length: 6)

        resultLabel.text = emailForm?.checkConsentMessage
        termsButton.titleLabel?.leading(to: termsButton)
        resultLabel.isHidden = true
        messageLabel.textAlignment = .natural
        titleLabel.top(to: self, offset: 50)
        messageLabel.topToBottom(of: titleLabel, offset: 10)
        emailTF.topToBottom(of: messageLabel, offset: 20)
        resultLabel.topToBottom(of: emailTF, offset: 10)
        firstCheckBox.topToBottom(of: resultLabel, offset: 10)
        termsButton.leadingToTrailing(of: firstCheckBox, offset: 10)
        termsButton.centerY(to: firstCheckBox)
        termsButton.trailing(to: self, offset: -12)
        let attrStr = NSMutableAttributedString(string: parsedPermit.string)
        attrStr.addAttribute(.link, value: emailForm?.emailPermitUrl?.absoluteString ?? "",
                             range: NSRange(location: parsedPermit.location, length: parsedPermit.length))
        termsButton.setAttributedTitle(attrStr, for: .normal)
        termsButton.titleLabel?.font = .systemFont(ofSize: CGFloat(emailForm?.permitTextSize ?? 10))
        firstCheckBox.size(CGSize(width: 20, height: 20))
        firstCheckBox.leading(to: self, offset: 20)

        titleLabel.leading(to: self, offset: 20)
        messageLabel.leading(to: titleLabel)
        messageLabel.trailing(to: self, offset: -20)
        emailTF.leading(to: self, offset: 20)
        emailTF.trailing(to: self, offset: -20.0)
        resultLabel.leading(to: firstCheckBox)

        if let consent = emailForm?.consentText {
            addSubview(secondCheckBox)
            addSubview(consentButton)

            consentButton.titleLabel?.leading(to: consentButton)
            secondCheckBox.topToBottom(of: firstCheckBox, offset: 10)
            secondCheckBox.leading(to: self, offset: 20)
            secondCheckBox.size(CGSize(width: 20, height: 20))
            secondCheckBox.bottom(to: self, offset: -40)
            consentButton.leadingToTrailing(of: secondCheckBox, offset: 10)
            consentButton.centerY(to: secondCheckBox)
            consentButton.trailing(to: self, offset: -12)

            let attrConsent = NSMutableAttributedString(string: consent.string)
            attrConsent.addAttribute(.link, value: emailForm?.consentUrl?.absoluteString ?? "",
                                     range: NSRange(location: consent.location, length: consent.length))
            consentButton.setAttributedTitle(attrConsent, for: .normal)
            consentButton.titleLabel?.font = .systemFont(ofSize: CGFloat(emailForm?.consentTextSize ?? 10))
        } else { // second checkbox and labels does not exist
            firstCheckBox.bottom(to: self, offset: -60)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    internal func setupForDefault() {
        addSubview(titleLabel)
        addSubview(messageLabel)

        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 8.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        messageLabel.bottom(to: self, offset: -10.0)
    }

    private func setBorderColorOfCell() -> UIColor {
        guard let bgColor = backgroundColor else { return .white }
        let red = bgColor.rgba.red
        let green = bgColor.rgba.green
        let blue = bgColor.rgba.blue
        let tot = red + green + blue
        if tot < 2.7 {
            return .white
        } else {
            return .black
        }
    }
}

extension RDPopupDialogDefaultView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberRange = rdInAppNotification?.numberRange
        var nWidth: CGFloat = 0.0
        if numberRange == "0-10" {
            nWidth = (numberRating.frame.width - 100) / 11
        } else {
            nWidth = (numberRating.frame.width - 100) / 10
        }

        return CGSize(width: nWidth, height: nWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberRange = rdInAppNotification?.numberRange
        if numberRange == "0-10" {
            return 11
        } else {
            return 10
        }

    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RatingCollectionViewCell

        let numberRange = rdInAppNotification?.numberRange
        if numberRange == "0-10" {
            cell.rating = indexPath.row
        } else {
            cell.rating = indexPath.row + 1
        }

        cell.borderColor = numberBorderColor
        if colors.count == 11 || colors.count == 10 {
            cell.setGradient(colors: colors[indexPath.row])
        } else {
            cell.setBackgroundColor(numberBgColor)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? RatingCollectionViewCell else {
            return
        }
        let numberRange = rdInAppNotification?.numberRange
        if cell.isSelected {
            if numberRange == "0-10" {
                selectedNumber = indexPath.row
            } else {
                selectedNumber = indexPath.row + 1
            }

            npsDelegate?.ratingSelected()
        } else {
            selectedNumber = 10
            npsDelegate?.ratingUnselected()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let numberRange = rdInAppNotification?.numberRange
        if numberRange == "0-10" {
            return 8
        } else {
            return 10
        }

    }
}
