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
    
    init(frame: CGRect, notification: RDInAppNotification) {
        self.notification = notification
        super.init(frame: frame)
        setupTitle()
        
        if let notUrl = notification.imageUrl {
            setupImageView(url: notUrl)
        }
        setCloseButton()
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
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        imageView.setImage(withUrl: url)
        addSubview(imageView)
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
        titleLabel.leading(to: self, offset: 0, relation: .equal, priority: .required)
        titleLabel.trailing(to: self, offset: 0, relation: .equal, priority: .required)
        titleLabel.centerX(to: self,priority: .required)
        imageView?.topToBottom(of: self.titleLabel, offset: 0)
        imageView?.leading(to: self, offset: 0, relation: .equal, priority: .required)
        imageView?.trailing(to: self, offset: 0, relation: .equal, priority: .required)
        
        if let _ = notification.imageUrl {
            let screenSize: CGRect = UIScreen.main.bounds
            imageView.height(screenSize.height/3.3)
        }

        
        closeButton.top(to: self, offset: -5.0)
        closeButton.trailing(to: self, offset: -10.0)
        
        self.window?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0).isActive = true
        self.window?.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
        self.layoutIfNeeded()
        
        
    }
    
    override func layoutSubviews() {
        if titleLabel.text.isNilOrWhiteSpace {
            titleLabel.height(0)
            titleLabel.isHidden = true
        } else {
            titleLabel.height(titleLabel.intrinsicContentSize.height + 20 )
        }
        super.layoutSubviews()
    }
    
}
