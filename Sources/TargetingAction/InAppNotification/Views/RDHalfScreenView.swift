//
//  RDHalfScreenView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.11.2021.
//

import Foundation
import UIKit

class RDHalfScreenView: UIView {

    var notification: RDInAppNotification
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
        setupTitle()
        setCloseButton()
        // Setup image view after title and close button to ensure hierarchy if needed, 
        // though strictly order in init doesn't matter for property creation, 
        // layoutContent depends on them.
        // We call setupImageView before layoutContent.
        if let notUrl = notification.imageUrl {
            setupImageView(url: notUrl)
        }
        setupPromotionCode()
        layoutContent()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTitle() {
        titleLabel = UILabel()
        titleLabel.text = notification.messageTitle
        titleLabel.font = notification.messageTitleFont
        titleLabel.textColor = notification.messageTitleColor
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
    }

    private func setupImageView(url: URL) {
        imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setImage(withUrl: url) { [weak self] in
            self?.updateImageHeight()
        }
        addSubview(imageView)
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
        addSubview(promotionContainer!)
        
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
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.contentHorizontalAlignment = .right
        closeButton.clipsToBounds = false
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 35.0, weight: .regular)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 2.5, right: 2.5)
        if let closeButtonColor = notification.closeButtonColor {
            closeButton.setTitleColor(closeButtonColor, for: .normal)
        }
        addSubview(closeButton)
    }

    private func layoutContent() {
        self.backgroundColor = notification.backGroundColor
        titleLabel.top(to: self, offset: 0, relation: .equal, priority: .required)
        titleLabel.leading(to: self, offset: 0, relation: .equal, priority: .required)
        titleLabel.trailing(to: self, offset: 0, relation: .equal, priority: .required)
        titleLabel.centerX(to: self, priority: .required)
        imageView?.topToBottom(of: self.titleLabel, offset: 0)
        imageView?.leading(to: self, offset: 0, relation: .equal, priority: .required)
        imageView?.trailing(to: self, offset: 0, relation: .equal, priority: .required)

        if let _ = notification.imageUrl {
            // Initial height 0, will be updated when image loads
            imageHeightConstraint = imageView.height(0)
        }
        
        if let promotionContainer = promotionContainer {
            promotionContainer.topToBottom(of: imageView, offset: 0)
            promotionContainer.leading(to: self, offset: 0, relation: .equal, priority: .required)
            promotionContainer.trailing(to: self, offset: 0, relation: .equal, priority: .required)
            
            promotionCodeLabel?.center(in: promotionContainer)
            
            copyButton?.centerY(to: promotionContainer)
            copyButton?.trailing(to: promotionContainer, offset: -20)
            copyButton?.width(30)
            copyButton?.height(30)
        }

        closeButton.top(to: self, offset: -5.0)
        closeButton.trailing(to: self, offset: -10.0)

        self.window?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0).isActive = true
        self.window?.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
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
        if let image = imageView.image {
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

}


protocol RDHalfScreenViewDelegate: AnyObject {
    func halfScreenViewDidLoadImage(image: UIImage)
}
