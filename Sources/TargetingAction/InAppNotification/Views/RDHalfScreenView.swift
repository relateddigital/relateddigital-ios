//
//  RDHalfScreenView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.11.2021.
//

import Foundation
import UIKit

class RDHalfScreenView: UIView {

    static let closeButtonExtraSpace: CGFloat = 40.0

    var notification: RDInAppNotification
    var containerView: UIView!
    var titleLabel: UILabel!
    var imageView: UIImageView!
    var closeButton: UIButton!
    weak var delegate: RDHalfScreenViewDelegate?
    private var imageHeightConstraint: NSLayoutConstraint?
    
    var promotionContainer: UIView?
    var promotionCodeLabel: UILabel?
    var copyButton: UIButton?

    init(frame: CGRect, notification: RDInAppNotification) {
        self.notification = notification
        super.init(frame: frame)
        setupContainer()
        setupTitle()
        if let notUrl = notification.imageUrl {
            setupImageView(url: notUrl)
        }
        setupPromotionCode()
        setCloseButton()
        layoutContent()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContainer() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = false
        addSubview(containerView)
    }

    private func setupTitle() {
        titleLabel = UILabel()
        titleLabel.text = notification.messageTitle
        titleLabel.font = notification.messageTitleFont
        titleLabel.textColor = notification.messageTitleColor
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
    }

    private func setupImageView(url: URL) {
        imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setImage(withUrl: url) { [weak self] in
            self?.updateImageHeight()
        }
        containerView.addSubview(imageView)
    }
    
    private func updateImageHeight() {
        guard let image = imageView.image else { return }
        let aspectRatio = image.size.height / image.size.width
        let newHeight = self.frame.width * aspectRatio
        imageHeightConstraint?.constant = newHeight
        self.layoutIfNeeded()
        delegate?.halfScreenViewDidLoadImage(image: image)
    }

    private func setupPromotionCode() {
        guard let promoCode = notification.promotionCode, !promoCode.isEmpty else { return }
        
        promotionContainer = UIView()
        promotionContainer?.translatesAutoresizingMaskIntoConstraints = false
        promotionContainer?.backgroundColor = .clear
        containerView.addSubview(promotionContainer!)
        
        promotionCodeLabel = UILabel()
        promotionCodeLabel?.text = promoCode
        promotionCodeLabel?.font = notification.messageTitleFont
        promotionCodeLabel?.textColor = notification.promotionTextColor ?? notification.messageTitleColor
        promotionCodeLabel?.textAlignment = .center
        promotionCodeLabel?.translatesAutoresizingMaskIntoConstraints = false
        promotionContainer?.addSubview(promotionCodeLabel!)
        
        copyButton = UIButton()
        copyButton?.translatesAutoresizingMaskIntoConstraints = false
        let copyIcon = RDHelper.getUIImage(named: "RelatedCopyButton")
        copyButton?.setImage(copyIcon, for: .normal)
        copyButton?.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        promotionContainer?.addSubview(copyButton!)
    }

    private func setCloseButton() {
        closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.clipsToBounds = true
        closeButton.layer.cornerRadius = 15.0
        closeButton.layer.borderWidth = 0.5
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 20.0, weight: .bold)
        closeButton.contentHorizontalAlignment = .center
        closeButton.contentVerticalAlignment = .center
        closeButton.titleEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 1, right: 0)
        
        setupCloseButtonColors()
        addSubview(closeButton)
    }

    private func setupCloseButtonColors() {
        let isWhite = isWhiteColor(notification.closeButtonColor)
        if isWhite {
            closeButton.backgroundColor = .black
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        } else {
            closeButton.backgroundColor = .white
            closeButton.setTitleColor(notification.closeButtonColor ?? .black, for: .normal)
            closeButton.layer.borderColor = UIColor.black.withAlphaComponent(0.15).cgColor
        }
    }

    private func isWhiteColor(_ color: UIColor?) -> Bool {
        guard let color = color else { return false }
        var white: CGFloat = 0
        var alpha: CGFloat = 0
        if color.getWhite(&white, alpha: &alpha) {
            return white >= 0.95
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &alpha) {
            return r >= 0.95 && g >= 0.95 && b >= 0.95
        }
        return false
    }

    private func layoutContent() {
        self.backgroundColor = .clear
        containerView.backgroundColor = notification.backGroundColor
        
        containerView.leading(to: self, offset: 0, relation: .equal, priority: .required)
        containerView.trailing(to: self, offset: 0, relation: .equal, priority: .required)
        
        if notification.position == .top {
            containerView.top(to: self, offset: 0, relation: .equal, priority: .required)
            containerView.bottom(to: self, offset: -RDHalfScreenView.closeButtonExtraSpace, relation: .equal, priority: .required)
            
            closeButton.top(to: containerView, containerView.bottomAnchor, offset: 6.0)
            closeButton.trailing(to: self, offset: -16.0)
        } else {
            containerView.bottom(to: self, offset: 0, relation: .equal, priority: .required)
            containerView.top(to: self, offset: RDHalfScreenView.closeButtonExtraSpace, relation: .equal, priority: .required)
            
            closeButton.bottom(to: containerView, containerView.topAnchor, offset: -6.0)
            closeButton.trailing(to: self, offset: -16.0)
        }

        closeButton.width(30.0)
        closeButton.height(30.0)

        titleLabel.top(to: containerView, offset: 0, relation: .equal, priority: .required)
        titleLabel.leading(to: containerView, offset: 0, relation: .equal, priority: .required)
        titleLabel.trailing(to: containerView, offset: 0, relation: .equal, priority: .required)
        titleLabel.centerX(to: containerView, priority: .required)
        
        if let imageView = imageView {
            imageView.topToBottom(of: self.titleLabel, offset: 0)
            imageView.leading(to: containerView, offset: 0, relation: .equal, priority: .required)
            imageView.trailing(to: containerView, offset: 0, relation: .equal, priority: .required)

            if let _ = notification.imageUrl {
                imageHeightConstraint = imageView.height(0)
            }
        }
        
        if let promotionContainer = promotionContainer {
            if let imageView = imageView {
                promotionContainer.topToBottom(of: imageView, offset: 0)
            } else {
                promotionContainer.topToBottom(of: titleLabel, offset: 0)
            }
            promotionContainer.leading(to: containerView, offset: 0, relation: .equal, priority: .required)
            promotionContainer.trailing(to: containerView, offset: 0, relation: .equal, priority: .required)
            
            promotionCodeLabel?.center(in: promotionContainer)
            
            copyButton?.centerY(to: promotionContainer)
            copyButton?.trailing(to: promotionContainer, offset: -20)
            copyButton?.width(30)
            copyButton?.height(30)
        }

        self.layoutIfNeeded()
    }

    @objc func copyButtonTapped(_ sender: UIButton) {
        if let code = promotionCodeLabel?.text {
            UIPasteboard.general.string = code
            RDHelper.showCopiedClipboardMessage()
            RDHelper.setCopyButtonFeedback(button: sender)
        }
    }

    override func layoutSubviews() {
        if titleLabel.text.isNilOrWhiteSpace {
            titleLabel.height(0)
            titleLabel.isHidden = true
        } else {
            titleLabel.preferredMaxLayoutWidth = self.frame.width
            titleLabel.height(titleLabel.intrinsicContentSize.height + 20 )
        }
        
        if let promotionContainer = promotionContainer, let promotionCodeLabel = promotionCodeLabel {
            if promotionCodeLabel.text.isNilOrWhiteSpace {
                promotionContainer.height(0)
                promotionContainer.isHidden = true
            } else {
                let promoHeight = promotionCodeLabel.intrinsicContentSize.height + 20
                promotionContainer.height(promoHeight)
            }
        }
        
        super.layoutSubviews()
    }
    
    func getPreferredHeight() -> CGFloat {
        var titleHeight: CGFloat = 0.0
        if let text = titleLabel.text, !text.isEmptyOrWhitespace {
             let size = titleLabel.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
             titleHeight = size.height + 20 // +20 padding as in layoutSubviews
        }
        
        var imgHeight: CGFloat = 0.0
        if let image = imageView?.image {
             let aspectRatio = image.size.height / image.size.width
             imgHeight = self.frame.width * aspectRatio
        } else {
             imgHeight = imageHeightConstraint?.constant ?? 0
        }
        
        var promoHeight: CGFloat = 0.0
        if let promoContainer = promotionContainer, !promoContainer.isHidden {
            if let promoLabel = promotionCodeLabel, !promoLabel.text.isNilOrWhiteSpace {
                let size = promoLabel.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
                promoHeight = size.height + 20
            }
        }
        
        return titleHeight + imgHeight + promoHeight
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let pointInContainer = containerView.convert(point, from: self)
        if containerView.point(inside: pointInContainer, with: event) {
            return true
        }
        let pointInClose = closeButton.convert(point, from: self)
        let closeTouchBounds = closeButton.bounds.insetBy(dx: -10, dy: -10)
        if closeTouchBounds.contains(pointInClose) {
            return true
        }
        return false
    }
}

protocol RDHalfScreenViewDelegate: AnyObject {
    func halfScreenViewDidLoadImage(image: UIImage)
}
