//
//  RDNpsWithNumbersCollectionView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit

public class RDNpsWithNumbersCollectionView: UIView {

    typealias NSLC = NSLayoutConstraint
    
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

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
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

    
    internal func setImageView() -> UIImageView {
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
    
    internal func setMessageLabel() -> UILabel {
        let messageLabel = UILabel(frame: .zero)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = UIColor(white: 0.6, alpha: 1)
        messageLabel.font = .systemFont(ofSize: 14)
        return messageLabel
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

    // MARK: - VARIABLES

    internal lazy var imageView = setImageView()
    internal lazy var titleLabel = setTitleLabel()
    internal lazy var messageLabel = setMessageLabel()


    internal lazy var numberRating = setNumberRating()

    var colors: [[CGColor]] = []
    var numberBgColor: UIColor = .black
    var numberBorderColor: UIColor = .white
    var selectedNumber: Int?
    var expanded = false

    internal var imageHeightConstraint: NSLC?

    weak var rdInAppNotification: RDInAppNotification?
    var consentCheckboxAdded = false
    weak var delegate: RDNpsWithNumbersCollectionView?
    weak var npsDelegate: NPSDelegate?
    // MARK: - CONSTRUCTOR
    init(frame: CGRect, rdInAppNotification: RDInAppNotification?) {
        self.rdInAppNotification = rdInAppNotification
        super.init(frame: frame)
        if self.rdInAppNotification != nil {
            setupViews()
        }
        super.layoutIfNeeded()
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
        setupForNpsWithNumbers()

        imageHeightConstraint = NSLC(item: imageView,
            attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 0, constant: 0)

        if let imageHeightConstraint = imageHeightConstraint {
            constraints.append(imageHeightConstraint)
        }


        NSLC.activate(constraints)
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
       
        
    }
}

// MARK: - SliderStepDelegate

extension RDNpsWithNumbersCollectionView: SliderStepDelegate {
    func didSelectedValue(sliderStep: RDSliderStep, value: Float) {
        sliderStep.value = value
    }
}

extension RDNpsWithNumbersCollectionView: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    public func textFieldDidEndEditing(_ textField: UITextField) {

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

    func hideResultLabel() {
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }

    @objc func dismissKeyboard() {
        self.endEditing(true)
    }


}


extension RDNpsWithNumbersCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
